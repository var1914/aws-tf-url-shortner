import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient, GetItemCommand } from '@aws-sdk/client-dynamodb';

const dynamodb = new DynamoDBClient({});

export const handler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
  try {
    const shortId = event.pathParameters?.id;

    if (!shortId) {
      return {
        statusCode: 400,
        body: 'Short ID required'
      };
    }

    // Get URL from DynamoDB
    const result = await dynamodb.send(new GetItemCommand({
      TableName: process.env.TABLE_NAME!,
      Key: {
        short_id: { S: shortId }
      }
    }));

    if (!result.Item) {
      return {
        statusCode: 404,
        headers: { 'Content-Type': 'text/html' },
        body: '<h1>404 - URL Not Found</h1>'
      };
    }

    const originalUrl = result.Item.original_url.S!;

    // Basic security check
    if (!originalUrl.startsWith('http://') && !originalUrl.startsWith('https://')) {
      return {
        statusCode: 400,
        headers: { 'Content-Type': 'text/html' },
        body: '<h1>Invalid URL</h1>'
      };
    }

    // Redirect
    return {
      statusCode: 302,
      headers: {
        'Location': originalUrl,
        'Cache-Control': 'no-cache'
      },
      body: ''
    };

  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'text/html' },
      body: '<h1>500 - Internal Server Error</h1>'
    };
  }
};