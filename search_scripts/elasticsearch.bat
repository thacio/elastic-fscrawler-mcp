@echo off
REM Elasticsearch MCP Server using curl commands for Windows
REM This script provides MCP tools for Elasticsearch search

REM Default configuration
if "%ES_HOST%"=="" set ES_HOST=https://localhost:9200
if "%ES_USER%"=="" set ES_USER=elastic
if "%ES_PASS%"=="" set ES_PASS=changeme

if "%1"=="search" goto :search
if "%1"=="semantic_search" goto :semantic_search
if "%1"=="hybrid_search" goto :hybrid_search
if "%1"=="count" goto :count
if "%1"=="indices" goto :indices
goto :usage

:search
REM Traditional search with optional highlighting
set QUERY=%~2
set INDEX=%3
if "%INDEX%"=="" set INDEX=semantic_documents
set SIZE=%4
if "%SIZE%"=="" set SIZE=5
set HIGHLIGHT=%5
if "%HIGHLIGHT%"=="" set HIGHLIGHT=true
set FRAGMENT_SIZE=%6
if "%FRAGMENT_SIZE%"=="" set FRAGMENT_SIZE=600
set NUM_FRAGMENTS=%7
if "%NUM_FRAGMENTS%"=="" set NUM_FRAGMENTS=5

if "%HIGHLIGHT%"=="true" (
    set HIGHLIGHT_JSON=, \"highlight\": {\"fields\": {\"content\": {\"fragment_size\": %FRAGMENT_SIZE%, \"number_of_fragments\": %NUM_FRAGMENTS%, \"pre_tags\": [\"\"], \"post_tags\": [\"\"]}}}
    set SOURCE_FIELDS=[\"title\", \"file.filename\", \"file.last_modified\", \"path.real\", \"path.virtual\"]
) else (
    set HIGHLIGHT_JSON=
    set SOURCE_FIELDS=[\"title\", \"content\", \"file.filename\", \"file.last_modified\", \"path.real\", \"path.virtual\"]
)

curl -k -u "%ES_USER%:%ES_PASS%" -X POST "%ES_HOST%/%INDEX%/_search?pretty" -H "Content-Type: application/json" -d "{\"query\": {\"multi_match\": {\"query\": \"%QUERY%\", \"fields\": [\"content\", \"title\", \"file.filename\"]}}%HIGHLIGHT_JSON%, \"_source\": %SOURCE_FIELDS%, \"size\": %SIZE%}"
goto :end

:semantic_search
REM Semantic search with optional highlighting
set QUERY=%~2
set INDEX=%3
if "%INDEX%"=="" set INDEX=semantic_documents
set SIZE=%4
if "%SIZE%"=="" set SIZE=5
set HIGHLIGHT=%5
if "%HIGHLIGHT%"=="" set HIGHLIGHT=true
set FRAGMENT_SIZE=%6
if "%FRAGMENT_SIZE%"=="" set FRAGMENT_SIZE=600
set NUM_FRAGMENTS=%7
if "%NUM_FRAGMENTS%"=="" set NUM_FRAGMENTS=5

if "%HIGHLIGHT%"=="true" (
    set HIGHLIGHT_JSON=, \"highlight\": {\"fields\": {\"content\": {\"fragment_size\": %FRAGMENT_SIZE%, \"number_of_fragments\": %NUM_FRAGMENTS%, \"pre_tags\": [\"\"], \"post_tags\": [\"\"]}}}
    set SOURCE_FIELDS=[\"title\", \"author\", \"created_date\", \"tags\", \"file.filename\", \"file.last_modified\", \"path.real\", \"path.virtual\"]
) else (
    set HIGHLIGHT_JSON=
    set SOURCE_FIELDS=[\"title\", \"content\", \"content_semantic\", \"author\", \"created_date\", \"tags\", \"file.filename\", \"file.last_modified\", \"path.real\", \"path.virtual\"]
)

if "%HIGHLIGHT%"=="true" (
    curl -k -u "%ES_USER%:%ES_PASS%" -X POST "%ES_HOST%/%INDEX%/_search?pretty" -H "Content-Type: application/json" -d "{\"query\": {\"bool\": {\"should\": [{\"semantic\": {\"field\": \"content_semantic\", \"query\": \"%QUERY%\", \"boost\": 2.0}}, {\"multi_match\": {\"query\": \"%QUERY%\", \"fields\": [\"content\", \"title\"], \"boost\": 0.5}}]}}%HIGHLIGHT_JSON%, \"_source\": %SOURCE_FIELDS%, \"size\": %SIZE%}"
) else (
    curl -k -u "%ES_USER%:%ES_PASS%" -X POST "%ES_HOST%/%INDEX%/_search?pretty" -H "Content-Type: application/json" -d "{\"query\": {\"semantic\": {\"field\": \"content_semantic\", \"query\": \"%QUERY%\"}}, \"_source\": %SOURCE_FIELDS%, \"size\": %SIZE%}"
)
goto :end

:hybrid_search
REM Hybrid search using RRF (Reciprocal Rank Fusion)
set QUERY=%~2
set INDEX=%3
if "%INDEX%"=="" set INDEX=semantic_documents
set SIZE=%4
if "%SIZE%"=="" set SIZE=5
set HIGHLIGHT=%5
if "%HIGHLIGHT%"=="" set HIGHLIGHT=true
set FRAGMENT_SIZE=%6
if "%FRAGMENT_SIZE%"=="" set FRAGMENT_SIZE=600
set NUM_FRAGMENTS=%7
if "%NUM_FRAGMENTS%"=="" set NUM_FRAGMENTS=5
set RANK_WINDOW_SIZE=%8
if "%RANK_WINDOW_SIZE%"=="" set RANK_WINDOW_SIZE=50
set RANK_CONSTANT=%9
if "%RANK_CONSTANT%"=="" set RANK_CONSTANT=20

if "%HIGHLIGHT%"=="true" (
    set HIGHLIGHT_JSON=, \"highlight\": {\"fields\": {\"content\": {\"fragment_size\": %FRAGMENT_SIZE%, \"number_of_fragments\": %NUM_FRAGMENTS%, \"pre_tags\": [\"\"], \"post_tags\": [\"\"]}}}
    set SOURCE_FIELDS=[\"title\", \"file.filename\", \"file.last_modified\", \"path.real\", \"path.virtual\"]
) else (
    set HIGHLIGHT_JSON=
    set SOURCE_FIELDS=[\"title\", \"content\", \"file.filename\", \"file.last_modified\", \"path.real\", \"path.virtual\"]
)

curl -k -u "%ES_USER%:%ES_PASS%" -X POST "%ES_HOST%/%INDEX%/_search?pretty" -H "Content-Type: application/json" -d "{\"retriever\": {\"rrf\": {\"retrievers\": [{\"standard\": {\"query\": {\"multi_match\": {\"query\": \"%QUERY%\", \"fields\": [\"content\", \"title\", \"file.filename\"]}}}}, {\"standard\": {\"query\": {\"semantic\": {\"field\": \"content_semantic\", \"query\": \"%QUERY%\"}}}}], \"rank_window_size\": %RANK_WINDOW_SIZE%, \"rank_constant\": %RANK_CONSTANT%}}%HIGHLIGHT_JSON%, \"_source\": %SOURCE_FIELDS%, \"size\": %SIZE%}"
goto :end

:count
REM Document count
set INDEX=%2
if "%INDEX%"=="" set INDEX=semantic_documents

curl -k -u "%ES_USER%:%ES_PASS%" "%ES_HOST%/%INDEX%/_count?pretty"
goto :end

:indices
REM List indices
curl -k -u "%ES_USER%:%ES_PASS%" "%ES_HOST%/_cat/indices?v"
goto :end

:usage
echo Usage: %0 {search^|semantic_search^|hybrid_search^|count^|indices} ^<query^> [index] [size] [highlight] [fragment_size] [num_fragments] [rank_window_size] [rank_constant]
echo Examples:
echo   %0 search "contract agreement"
echo   %0 search "elementos" semantic_documents 5 true 200 2
echo   %0 search "legal documents" semantic_documents 5 true 200 2
echo   %0 semantic_search "legal documents"
echo   %0 semantic_search "auditoria dados" semantic_documents 10 true
echo   %0 hybrid_search "contract agreement"
echo   %0 hybrid_search "elementos evidências" semantic_documents 10 true 300 3 50 20
echo   %0 count semantic_documents
echo   %0 indices
echo.
echo Search Types:
echo   search: Traditional keyword-based search
echo   semantic_search: AI-powered semantic search using E5 model
echo   hybrid_search: RRF combination of both lexical and semantic search
echo.
echo Search Parameters:
echo   highlight: Enable highlighting with ^<mark^> tags (true/false, default: true)
echo   fragment_size: Characters per highlighted fragment (default: 600)
echo   num_fragments: Number of fragments to return (default: 5)
echo   rank_window_size: RRF rank window size (default: 50)
echo   rank_constant: RRF rank constant (default: 20)
exit /b 1

:end