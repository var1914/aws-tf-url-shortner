import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient, PutItemCommand } from '@aws-sdk/client-dynamodb';

const dynamodb = new DynamoDBClient({});

const generateId = (): string => Math.random().toString(36).substring(2, 8);

// Simple API key validation
const validateApiKey = (authHeader: string | undefined): boolean => {
  if (!authHeader) return false;
  
  // Support both "Bearer <key>" and "API-Key <key>" formats
  const token = authHeader.startsWith('Bearer ') 
    ? authHeader.substring(7)
    : authHeader.startsWith('API-Key ')
    ? authHeader.substring(8)
    : authHeader;

  // In production, you'd validate against a database or service
  // For this demo, we'll use environment variables
  const validApiKeys = (process.env.VALID_API_KEYS || '').split(',');
  
  return validApiKeys.includes(token.trim());
};

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key'
  };

  try {
    // Handle CORS
    if (event.httpMethod === 'OPTIONS') {
      return { statusCode: 200, headers, body: '' };
    }

    // API Key validation
    const authHeader = event.headers.Authorization || event.headers['X-API-Key'];
    
    if (!validateApiKey(authHeader)) {
      return {
        statusCode: 401,
        headers,
        body: JSON.stringify({ 
          error: 'Invalid or missing API key',
          message: 'Include valid API key in Authorization header (Bearer <key>) or X-API-Key header'
        })
      };
    }

    // Parse and validate request body
    let requestBody;
    try {
      requestBody = JSON.parse(event.body || '{}');
    } catch {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Invalid JSON in request body' })
      };
    }

    const { url } = requestBody;

    // URL validation
    if (!url || typeof url !== 'string') {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'URL is required and must be a string' })
      };
    }

    // Enhanced URL validation
    try {
      const urlObj = new URL(url);
      if (!['http:', 'https:'].includes(urlObj.protocol)) {
        throw new Error('Invalid protocol');
      }
    } catch {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Valid HTTP/HTTPS URL required' })
      };
    }

    const shortId = generateId();
    const timestamp = new Date().toISOString();
    
    // Store in DynamoDB with metadata
    await dynamodb.send(new PutItemCommand({
      TableName: process.env.TABLE_NAME!,
      Item: {
        short_id: { S: shortId },
        original_url: { S: url },
        created_at: { S: timestamp },
        // Optional: track which API key created this (for analytics)
        created_by: { S: authHeader?.substring(0, 10) + '...' || 'unknown' }
      }
    }));

    const baseUrl = `https://${event.requestContext.domainName}/${event.requestContext.stage}`;
    
    return {
      statusCode: 201,
      headers,
      body: JSON.stringify({
        success: true,
        data: {
          shortId,
          shortUrl: `${baseUrl}/${shortId}`,
          originalUrl: url,
          createdAt: timestamp
        }
      })
    };

  } catch (error) {
    console.error('Error creating short URL:', error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ 
        error: 'Internal server error',
        message: 'Failed to create short URL'
      })
    };
  }
};