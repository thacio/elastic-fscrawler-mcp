@echo off
REM Elasticsearch MCP Server using curl commands for Windows
REM This script provides MCP tools for Elasticsearch search

REM Default configuration
if "%ES_HOST%"=="" set ES_HOST=https://localhost:9200
if "%ES_USER%"=="" set ES_USER=elastic
if "%ES_PASS%"=="" set ES_PASS=changeme

if "%1"=="search" goto :search
if "%1"=="semantic_search" goto :semantic_search
if "%1"=="count" goto :count
if "%1"=="indices" goto :indices
goto :usage

:search
REM Traditional search with highlighting
set QUERY=%~2
set INDEX=%3
if "%INDEX%"=="" set INDEX=idx
set SIZE=%4
if "%SIZE%"=="" set SIZE=10
set FRAGMENT_SIZE=%5
if "%FRAGMENT_SIZE%"=="" set FRAGMENT_SIZE=300
set NUM_FRAGMENTS=%6
if "%NUM_FRAGMENTS%"=="" set NUM_FRAGMENTS=3

curl -k -u "%ES_USER%:%ES_PASS%" -X POST "%ES_HOST%/%INDEX%/_search?pretty" -H "Content-Type: application/json" -d "{\"query\": {\"multi_match\": {\"query\": \"%QUERY%\", \"fields\": [\"content\", \"title\", \"file.filename\"]}}, \"highlight\": {\"fields\": {\"content\": {\"fragment_size\": %FRAGMENT_SIZE%, \"number_of_fragments\": %NUM_FRAGMENTS%, \"pre_tags\": [\"^<mark^>\"], \"post_tags\": [\"^</mark^>\"]}}}, \"_source\": [\"title\", \"file.filename\", \"file.last_modified\", \"path.real\"], \"size\": %SIZE%}"
goto :end

:semantic_search
REM Semantic search with highlighting
set QUERY=%~2
set INDEX=%3
if "%INDEX%"=="" set INDEX=semantic_documents
set SIZE=%4
if "%SIZE%"=="" set SIZE=10
set FRAGMENT_SIZE=%5
if "%FRAGMENT_SIZE%"=="" set FRAGMENT_SIZE=300
set NUM_FRAGMENTS=%6
if "%NUM_FRAGMENTS%"=="" set NUM_FRAGMENTS=3

curl -k -u "%ES_USER%:%ES_PASS%" -X POST "%ES_HOST%/%INDEX%/_search?pretty" -H "Content-Type: application/json" -d "{\"query\": {\"semantic\": {\"field\": \"content_semantic\", \"query\": \"%QUERY%\"}}, \"highlight\": {\"fields\": {\"content\": {\"fragment_size\": %FRAGMENT_SIZE%, \"number_of_fragments\": %NUM_FRAGMENTS%, \"pre_tags\": [\"^<mark^>\"], \"post_tags\": [\"^</mark^>\"]}}}, \"_source\": [\"title\", \"author\", \"created_date\", \"tags\"], \"size\": %SIZE%}"
goto :end

:count
REM Document count
set INDEX=%2
if "%INDEX%"=="" set INDEX=idx

curl -k -u "%ES_USER%:%ES_PASS%" "%ES_HOST%/%INDEX%/_count?pretty"
goto :end

:indices
REM List indices
curl -k -u "%ES_USER%:%ES_PASS%" "%ES_HOST%/_cat/indices?v"
goto :end

:usage
echo Usage: %0 {search^|semantic_search^|count^|indices} ^<query^> [index] [size] [fragment_size] [num_fragments]
echo Examples:
echo   %0 search "contract agreement"
echo   %0 search "legal documents" idx 5 200 2
echo   %0 semantic_search "legal documents"
echo   %0 count idx
echo   %0 indices
echo.
echo Search Parameters:
echo   fragment_size: Characters per highlighted fragment (default: 300)
echo   num_fragments: Number of fragments to return (default: 3)
exit /b 1

:end