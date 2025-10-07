"""
WebSocket testing utilities for integration tests.

Provides helper classes and functions for testing WebSocket endpoints.
"""

import asyncio
import json
from typing import Dict, Any, Optional, List
from httpx import AsyncClient
import websockets
from websockets.client import WebSocketClientProtocol


class WebSocketTestClient:
    """
    Test client for WebSocket connections.

    Provides utilities for connecting to WebSocket endpoints and
    testing message exchange.
    """

    def __init__(self, base_url: str = "ws://localhost:8000"):
        self.base_url = base_url
        self.websocket: Optional[WebSocketClientProtocol] = None
        self.received_messages: List[Dict[str, Any]] = []

    async def connect(self, endpoint: str, params: Optional[Dict[str, str]] = None):
        """
        Connect to a WebSocket endpoint.

        Args:
            endpoint: WebSocket endpoint path (e.g., "/ws/jobs")
            params: Optional query parameters
        """
        url = f"{self.base_url}{endpoint}"

        if params:
            query_string = "&".join([f"{k}={v}" for k, v in params.items()])
            url = f"{url}?{query_string}"

        self.websocket = await websockets.connect(url)

    async def disconnect(self):
        """Close the WebSocket connection."""
        if self.websocket:
            await self.websocket.close()
            self.websocket = None

    async def send_json(self, data: Dict[str, Any]):
        """
        Send JSON data over the WebSocket.

        Args:
            data: Dictionary to send as JSON
        """
        if not self.websocket:
            raise RuntimeError("WebSocket not connected")

        await self.websocket.send(json.dumps(data))

    async def receive_json(self, timeout: float = 5.0) -> Dict[str, Any]:
        """
        Receive and parse JSON data from the WebSocket.

        Args:
            timeout: Maximum time to wait for a message in seconds

        Returns:
            Parsed JSON data

        Raises:
            asyncio.TimeoutError: If no message is received within timeout
        """
        if not self.websocket:
            raise RuntimeError("WebSocket not connected")

        message = await asyncio.wait_for(
            self.websocket.recv(),
            timeout=timeout
        )

        data = json.loads(message)
        self.received_messages.append(data)
        return data

    async def receive_until(
        self,
        condition: callable,
        timeout: float = 10.0,
        max_messages: int = 100
    ) -> Optional[Dict[str, Any]]:
        """
        Receive messages until a condition is met.

        Args:
            condition: Function that takes a message dict and returns True when found
            timeout: Maximum time to wait
            max_messages: Maximum number of messages to check

        Returns:
            The message that matches the condition, or None if not found
        """
        start_time = asyncio.get_event_loop().time()
        messages_checked = 0

        while messages_checked < max_messages:
            if asyncio.get_event_loop().time() - start_time > timeout:
                raise asyncio.TimeoutError("Timeout waiting for condition")

            try:
                message = await self.receive_json(timeout=1.0)
                messages_checked += 1

                if condition(message):
                    return message
            except asyncio.TimeoutError:
                # No message received in 1 second, continue waiting
                continue

        return None

    def clear_messages(self):
        """Clear the received messages buffer."""
        self.received_messages.clear()

    async def __aenter__(self):
        """Context manager entry."""
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        await self.disconnect()


class SSETestClient:
    """
    Test client for Server-Sent Events (SSE) endpoints.

    Provides utilities for testing SSE streaming endpoints.
    """

    def __init__(self, client: AsyncClient):
        self.client = client

    async def connect_sse(
        self,
        endpoint: str,
        params: Optional[Dict[str, Any]] = None
    ):
        """
        Connect to an SSE endpoint and yield events.

        Args:
            endpoint: SSE endpoint path
            params: Optional query parameters

        Yields:
            Parsed SSE events as dictionaries
        """
        async with self.client.stream("GET", endpoint, params=params) as response:
            async for line in response.aiter_lines():
                if line.startswith("data: "):
                    data_str = line[6:]  # Remove "data: " prefix
                    try:
                        yield json.loads(data_str)
                    except json.JSONDecodeError:
                        yield {"raw": data_str}
                elif line.startswith("event: "):
                    # Event type line
                    event_type = line[7:]
                    yield {"event_type": event_type}


async def wait_for_websocket_message(
    ws_client: WebSocketTestClient,
    message_type: str,
    timeout: float = 5.0
) -> Optional[Dict[str, Any]]:
    """
    Wait for a specific type of WebSocket message.

    Args:
        ws_client: WebSocket test client
        message_type: Type of message to wait for
        timeout: Maximum time to wait

    Returns:
        The matching message, or None if not found
    """
    return await ws_client.receive_until(
        condition=lambda msg: msg.get("type") == message_type,
        timeout=timeout
    )


async def send_and_receive(
    ws_client: WebSocketTestClient,
    send_data: Dict[str, Any],
    expected_type: Optional[str] = None,
    timeout: float = 5.0
) -> Dict[str, Any]:
    """
    Send a message and wait for a response.

    Args:
        ws_client: WebSocket test client
        send_data: Data to send
        expected_type: Expected message type in response (optional)
        timeout: Maximum time to wait for response

    Returns:
        The response message
    """
    await ws_client.send_json(send_data)

    if expected_type:
        return await wait_for_websocket_message(ws_client, expected_type, timeout)
    else:
        return await ws_client.receive_json(timeout)
