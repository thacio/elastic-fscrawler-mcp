#!/usr/bin/env python3
"""
Test script to verify MCP server functionality
"""

import asyncio
import sys
from fastmcp import Client

async def test_mcp_server():
    """Test the MCP server functionality"""
    print("🧪 Testing MCP Server...")
    
    try:
        # Connect to the MCP server
        async with Client("http://localhost:8081/mcp/") as client:
            print("✅ Successfully connected to MCP server")
            
            # Test 1: List available tools
            print("\n📋 Testing: List Tools")
            tools = await client.list_tools()
            print(f"Available tools: {[tool.name for tool in tools]}")
            print(f"Total tools found: {len(tools)}")
            
            # Test 2: List available resources
            print("\n📋 Testing: List Resources")
            resources = await client.list_resources()
            print(f"Available resources: {[resource.uri for resource in resources]}")
            print(f"Total resources found: {len(resources)}")
            
            # Test 3: Health check
            print("\n💚 Testing: Health Check")
            health = await client.call_tool("health_check", {})
            print(f"Elasticsearch health: {health.data}")
            
            # Test 4: Server health
            print("\n💚 Testing: Server Health")
            server_health = await client.call_tool("server_health", {})
            print(f"MCP server health: {server_health.data}")
            
            # Test 5: List indices
            print("\n📊 Testing: List Indices")
            indices = await client.call_tool("list_indices", {})
            print(f"Available indices: {indices.data}")
            
            # Test 6: Count documents
            print("\n🔢 Testing: Count Documents")
            count = await client.call_tool("count_documents", {"index": "documents"})
            print(f"Document count: {count.data}")
            
            # Test 7: Get search statistics resource
            print("\n📈 Testing: Search Statistics Resource")
            try:
                stats = await client.read_resource("elasticsearch://stats")
                print(f"Search stats: {stats.data}")
            except Exception as e:
                print(f"⚠️  Search stats error: {e}")
            
            # Test 8: Search (if documents exist)
            document_count = count.data.get("count", 0)
            if document_count > 0:
                print(f"\n🔍 Testing: Search (found {document_count} documents)")
                search_result = await client.call_tool("search", {
                    "query": "test",
                    "size": 2,
                    "highlight": True
                })
                print(f"Search results: {search_result.data}")
                
                print("\n🧠 Testing: Semantic Search")
                semantic_result = await client.call_tool("semantic_search", {
                    "query": "document analysis",
                    "size": 2,
                    "highlight": True
                })
                print(f"Semantic search results: {semantic_result.data}")
                
                print("\n🔄 Testing: Hybrid Search")
                hybrid_result = await client.call_tool("hybrid_search", {
                    "query": "test document",
                    "size": 2,
                    "highlight": True
                })
                print(f"Hybrid search results: {hybrid_result.data}")
            else:
                print("\n⚠️  No documents found in index - skipping search tests")
                print("   To test search functionality, add documents to ./elastic_documents/")
            
            print("\n✅ All MCP server tests completed successfully!")
            return True
            
    except Exception as e:
        print(f"❌ Error testing MCP server: {e}")
        return False

async def main():
    """Main test function"""
    print("🚀 MCP Server Test Suite")
    print("=" * 50)
    
    success = await test_mcp_server()
    
    if success:
        print("\n🎉 MCP Server is working correctly!")
        sys.exit(0)
    else:
        print("\n💥 MCP Server tests failed!")
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())