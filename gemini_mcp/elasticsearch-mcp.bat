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
REM Traditional search
set QUERY=%~2
set INDEX=%3
if "%INDEX%"=="" set INDEX=idx
set SIZE=%4
if "%SIZE%"=="" set SIZE=10

curl -k -u "%ES_USER%:%ES_PASS%" "%ES_HOST%/%INDEX%/_search?q=%QUERY%&size=%SIZE%&pretty"
goto :end

:semantic_search
REM Semantic search
set QUERY=%~2
set INDEX=%3
if "%INDEX%"=="" set INDEX=semantic_documents
set SIZE=%4
if "%SIZE%"=="" set SIZE=10

curl -k -u "%ES_USER%:%ES_PASS%" -X POST "%ES_HOST%/%INDEX%/_search?pretty" -H "Content-Type: application/json" -d "{\"query\": {\"semantic\": {\"field\": \"content_semantic\", \"query\": \"%QUERY%\"}}, \"size\": %SIZE%}"
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
echo Usage: %0 {search^|semantic_search^|count^|indices} ^<query^> [index] [size]
echo Examples:
echo   %0 search "contract agreement"
echo   %0 semantic_search "legal documents"
echo   %0 count idx
echo   %0 indices
exit /b 1

:end