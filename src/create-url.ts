import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient, PutItemCommand } from '@aws-sdk/client-dynamodb';

const dynamodb = new DynamoDBClient({});

const generateId = (): string => Math.random().toString(36).substring(2, 8);

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  const headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
  };

  try {
    // Handle CORS
    if (event.httpMethod === 'OPTIONS') {
      return { statusCode: 200, headers, body: '' };
    }

    // Basic auth check
    if (!event.headers.Authorization) {
      return {
        statusCode: 401,
        headers,
        body: JSON.stringify({ error: 'Authorization required' })
      };
    }

    const { url } = JSON.parse(event.body || '{}');

    // Simple validation
    if (!url || !url.startsWith('http')) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Valid URL required' })
      };
    }

    const shortId = generateId();
    
    // Store in DynamoDB
    await dynamodb.send(new PutItemCommand({
      TableName: process.env.TABLE_NAME!,
      Item: {
        short_id: { S: shortId },
        original_url: { S: url },
        created_at: { S: new Date().toISOString() }
      }
    }));

    const baseUrl = `https://${event.requestContext.domainName}/${event.requestContext.stage}`;
    
    return {
      statusCode: 201,
      headers,
      body: JSON.stringify({
        shortId,
        shortUrl: `${baseUrl}/${shortId}`,
        originalUrl: url
      })
    };

  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: 'Internal server error' })
    };
  }
};