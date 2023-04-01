---Generated on 2023-04-01-18:54:28 GMT

---@class nio.lsp.RequestClient
local LSPRequestClient = {}
---@class nio.lsp.RequestOpts
---@field timeout integer Timeout of request in milliseconds
---@class nio.lsp.types.ResponseError
---@field code number A number indicating the error type that occurred.
---@field message string A string providing a short description of the error.
---@field data any A Primitive or Structured value that contains additional information about the error. Can be omitted.

--- A request to resolve the implementation locations of a symbol at a given text
--- document position. The request's parameter is of type [TextDocumentPositionParams]
--- (#TextDocumentPositionParams) the response is of type [Definition](#Definition) or a
--- Thenable that resolves to such.
---@async
---@param args nio.lsp.types.ImplementationParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.Definition|nio.lsp.types.DefinitionLink[]|nil result The result of the request
function LSPRequestClient.textDocument_implementation(args, bufnr, opts) end

--- A request to resolve the type definition locations of a symbol at a given text
--- document position. The request's parameter is of type [TextDocumentPositionParams]
--- (#TextDocumentPositionParams) the response is of type [Definition](#Definition) or a
--- Thenable that resolves to such.
---@async
---@param args nio.lsp.types.TypeDefinitionParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.Definition|nio.lsp.types.DefinitionLink[]|nil result The result of the request
function LSPRequestClient.textDocument_typeDefinition(args, bufnr, opts) end

--- A request to list all color symbols found in a given text document. The request's
--- parameter is of type [DocumentColorParams](#DocumentColorParams) the
--- response is of type [ColorInformation[]](#ColorInformation) or a Thenable
--- that resolves to such.
---@async
---@param args nio.lsp.types.DocumentColorParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.ColorInformation[]|nil result The result of the request
function LSPRequestClient.textDocument_documentColor(args, bufnr, opts) end

--- A request to list all presentation for a color. The request's
--- parameter is of type [ColorPresentationParams](#ColorPresentationParams) the
--- response is of type [ColorInformation[]](#ColorInformation) or a Thenable
--- that resolves to such.
---@async
---@param args nio.lsp.types.ColorPresentationParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.ColorPresentation[]|nil result The result of the request
function LSPRequestClient.textDocument_colorPresentation(args, bufnr, opts) end

--- A request to provide folding ranges in a document. The request's
--- parameter is of type [FoldingRangeParams](#FoldingRangeParams), the
--- response is of type [FoldingRangeList](#FoldingRangeList) or a Thenable
--- that resolves to such.
---@async
---@param args nio.lsp.types.FoldingRangeParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.FoldingRange[]|nil result The result of the request
function LSPRequestClient.textDocument_foldingRange(args, bufnr, opts) end

--- A request to resolve the type definition locations of a symbol at a given text
--- document position. The request's parameter is of type [TextDocumentPositionParams]
--- (#TextDocumentPositionParams) the response is of type [Declaration](#Declaration)
--- or a typed array of [DeclarationLink](#DeclarationLink) or a Thenable that resolves
--- to such.
---@async
---@param args nio.lsp.types.DeclarationParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.Declaration|nio.lsp.types.DeclarationLink[]|nil result The result of the request
function LSPRequestClient.textDocument_declaration(args, bufnr, opts) end

--- A request to provide selection ranges in a document. The request's
--- parameter is of type [SelectionRangeParams](#SelectionRangeParams), the
--- response is of type [SelectionRange[]](#SelectionRange[]) or a Thenable
--- that resolves to such.
---@async
---@param args nio.lsp.types.SelectionRangeParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.SelectionRange[]|nil result The result of the request
function LSPRequestClient.textDocument_selectionRange(args, bufnr, opts) end

--- A request to result a `CallHierarchyItem` in a document at a given position.
--- Can be used as an input to an incoming or outgoing call hierarchy.
---
--- @since 3.16.0
---@async
---@param args nio.lsp.types.CallHierarchyPrepareParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.CallHierarchyItem[]|nil result The result of the request
function LSPRequestClient.textDocument_prepareCallHierarchy(args, bufnr, opts) end

--- A request to resolve the incoming calls for a given `CallHierarchyItem`.
---
--- @since 3.16.0
---@async
---@param args nio.lsp.types.CallHierarchyIncomingCallsParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.CallHierarchyIncomingCall[]|nil result The result of the request
function LSPRequestClient.callHierarchy_incomingCalls(args, bufnr, opts) end

--- A request to resolve the outgoing calls for a given `CallHierarchyItem`.
---
--- @since 3.16.0
---@async
---@param args nio.lsp.types.CallHierarchyOutgoingCallsParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.CallHierarchyOutgoingCall[]|nil result The result of the request
function LSPRequestClient.callHierarchy_outgoingCalls(args, bufnr, opts) end

--- @since 3.16.0
---@async
---@param args nio.lsp.types.SemanticTokensParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.SemanticTokens|nil result The result of the request
function LSPRequestClient.textDocument_semanticTokens_full(args, bufnr, opts) end

--- @since 3.16.0
---@async
---@param args nio.lsp.types.SemanticTokensDeltaParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.SemanticTokens|nio.lsp.types.SemanticTokensDelta|nil result The result of the request
function LSPRequestClient.textDocument_semanticTokens_full_delta(args, bufnr, opts) end

--- @since 3.16.0
---@async
---@param args nio.lsp.types.SemanticTokensRangeParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.SemanticTokens|nil result The result of the request
function LSPRequestClient.textDocument_semanticTokens_range(args, bufnr, opts) end

--- @since 3.16.0
---@async
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nil|nil result The result of the request
function LSPRequestClient.workspace_semanticTokens_refresh(bufnr, opts) end

--- A request to provide ranges that can be edited together.
---
--- @since 3.16.0
---@async
---@param args nio.lsp.types.LinkedEditingRangeParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.LinkedEditingRanges|nil result The result of the request
function LSPRequestClient.textDocument_linkedEditingRange(args, bufnr, opts) end

--- The will create files request is sent from the client to the server before files are actually
--- created as long as the creation is triggered from within the client.
---
--- @since 3.16.0
---@async
---@param args nio.lsp.types.CreateFilesParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.WorkspaceEdit|nil result The result of the request
function LSPRequestClient.workspace_willCreateFiles(args, bufnr, opts) end

--- The will rename files request is sent from the client to the server before files are actually
--- renamed as long as the rename is triggered from within the client.
---
--- @since 3.16.0
---@async
---@param args nio.lsp.types.RenameFilesParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.WorkspaceEdit|nil result The result of the request
function LSPRequestClient.workspace_willRenameFiles(args, bufnr, opts) end

--- The did delete files notification is sent from the client to the server when
--- files were deleted from within the client.
---
--- @since 3.16.0
---@async
---@param args nio.lsp.types.DeleteFilesParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.WorkspaceEdit|nil result The result of the request
function LSPRequestClient.workspace_willDeleteFiles(args, bufnr, opts) end

--- A request to get the moniker of a symbol at a given text document position.
--- The request parameter is of type [TextDocumentPositionParams](#TextDocumentPositionParams).
--- The response is of type [Moniker[]](#Moniker[]) or `null`.
---@async
---@param args nio.lsp.types.MonikerParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.Moniker[]|nil result The result of the request
function LSPRequestClient.textDocument_moniker(args, bufnr, opts) end

--- A request to result a `TypeHierarchyItem` in a document at a given position.
--- Can be used as an input to a subtypes or supertypes type hierarchy.
---
--- @since 3.17.0
---@async
---@param args nio.lsp.types.TypeHierarchyPrepareParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.TypeHierarchyItem[]|nil result The result of the request
function LSPRequestClient.textDocument_prepareTypeHierarchy(args, bufnr, opts) end

--- A request to resolve the supertypes for a given `TypeHierarchyItem`.
---
--- @since 3.17.0
---@async
---@param args nio.lsp.types.TypeHierarchySupertypesParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.TypeHierarchyItem[]|nil result The result of the request
function LSPRequestClient.typeHierarchy_supertypes(args, bufnr, opts) end

--- A request to resolve the subtypes for a given `TypeHierarchyItem`.
---
--- @since 3.17.0
---@async
---@param args nio.lsp.types.TypeHierarchySubtypesParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.TypeHierarchyItem[]|nil result The result of the request
function LSPRequestClient.typeHierarchy_subtypes(args, bufnr, opts) end

--- A request to provide inline values in a document. The request's parameter is of
--- type [InlineValueParams](#InlineValueParams), the response is of type
--- [InlineValue[]](#InlineValue[]) or a Thenable that resolves to such.
---
--- @since 3.17.0
---@async
---@param args nio.lsp.types.InlineValueParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.InlineValue[]|nil result The result of the request
function LSPRequestClient.textDocument_inlineValue(args, bufnr, opts) end

--- @since 3.17.0
---@async
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nil|nil result The result of the request
function LSPRequestClient.workspace_inlineValue_refresh(bufnr, opts) end

--- A request to provide inlay hints in a document. The request's parameter is of
--- type [InlayHintsParams](#InlayHintsParams), the response is of type
--- [InlayHint[]](#InlayHint[]) or a Thenable that resolves to such.
---
--- @since 3.17.0
---@async
---@param args nio.lsp.types.InlayHintParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.InlayHint[]|nil result The result of the request
function LSPRequestClient.textDocument_inlayHint(args, bufnr, opts) end

--- A request to resolve additional properties for an inlay hint.
--- The request's parameter is of type [InlayHint](#InlayHint), the response is
--- of type [InlayHint](#InlayHint) or a Thenable that resolves to such.
---
--- @since 3.17.0
---@async
---@param args nio.lsp.types.InlayHint Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.InlayHint|nil result The result of the request
function LSPRequestClient.inlayHint_resolve(args, bufnr, opts) end

--- @since 3.17.0
---@async
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nil|nil result The result of the request
function LSPRequestClient.workspace_inlayHint_refresh(bufnr, opts) end

--- The document diagnostic request definition.
---
--- @since 3.17.0
---@async
---@param args nio.lsp.types.DocumentDiagnosticParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.DocumentDiagnosticReport|nil result The result of the request
function LSPRequestClient.textDocument_diagnostic(args, bufnr, opts) end

--- The workspace diagnostic request definition.
---
--- @since 3.17.0
---@async
---@param args nio.lsp.types.WorkspaceDiagnosticParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.WorkspaceDiagnosticReport|nil result The result of the request
function LSPRequestClient.workspace_diagnostic(args, bufnr, opts) end

--- The diagnostic refresh request definition.
---
--- @since 3.17.0
---@async
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nil|nil result The result of the request
function LSPRequestClient.workspace_diagnostic_refresh(bufnr, opts) end

--- The initialize request is sent from the client to the server.
--- It is sent once as the request after starting up the server.
--- The requests parameter is of type [InitializeParams](#InitializeParams)
--- the response if of type [InitializeResult](#InitializeResult) of a Thenable that
--- resolves to such.
---@async
---@param args nio.lsp.types.InitializeParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.InitializeResult|nil result The result of the request
function LSPRequestClient.initialize(args, bufnr, opts) end

--- A shutdown request is sent from the client to the server.
--- It is sent once when the client decides to shutdown the
--- server. The only notification that is sent after a shutdown request
--- is the exit event.
---@async
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nil|nil result The result of the request
function LSPRequestClient.shutdown(bufnr, opts) end

--- A document will save request is sent from the client to the server before
--- the document is actually saved. The request can return an array of TextEdits
--- which will be applied to the text document before it is saved. Please note that
--- clients might drop results if computing the text edits took too long or if a
--- server constantly fails on this request. This is done to keep the save fast and
--- reliable.
---@async
---@param args nio.lsp.types.WillSaveTextDocumentParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.TextEdit[]|nil result The result of the request
function LSPRequestClient.textDocument_willSaveWaitUntil(args, bufnr, opts) end

--- Request to request completion at a given text document position. The request's
--- parameter is of type [TextDocumentPosition](#TextDocumentPosition) the response
--- is of type [CompletionItem[]](#CompletionItem) or [CompletionList](#CompletionList)
--- or a Thenable that resolves to such.
---
--- The request can delay the computation of the [`detail`](#CompletionItem.detail)
--- and [`documentation`](#CompletionItem.documentation) properties to the `completionItem/resolve`
--- request. However, properties that are needed for the initial sorting and filtering, like `sortText`,
--- `filterText`, `insertText`, and `textEdit`, must not be changed during resolve.
---@async
---@param args nio.lsp.types.CompletionParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.CompletionItem[]|nio.lsp.types.CompletionList|nil result The result of the request
function LSPRequestClient.textDocument_completion(args, bufnr, opts) end

--- Request to resolve additional information for a given completion item.The request's
--- parameter is of type [CompletionItem](#CompletionItem) the response
--- is of type [CompletionItem](#CompletionItem) or a Thenable that resolves to such.
---@async
---@param args nio.lsp.types.CompletionItem Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.CompletionItem|nil result The result of the request
function LSPRequestClient.completionItem_resolve(args, bufnr, opts) end

--- Request to request hover information at a given text document position. The request's
--- parameter is of type [TextDocumentPosition](#TextDocumentPosition) the response is of
--- type [Hover](#Hover) or a Thenable that resolves to such.
---@async
---@param args nio.lsp.types.HoverParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.Hover|nil result The result of the request
function LSPRequestClient.textDocument_hover(args, bufnr, opts) end

---@async
---@param args nio.lsp.types.SignatureHelpParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.SignatureHelp|nil result The result of the request
function LSPRequestClient.textDocument_signatureHelp(args, bufnr, opts) end

--- A request to resolve the definition location of a symbol at a given text
--- document position. The request's parameter is of type [TextDocumentPosition]
--- (#TextDocumentPosition) the response is of either type [Definition](#Definition)
--- or a typed array of [DefinitionLink](#DefinitionLink) or a Thenable that resolves
--- to such.
---@async
---@param args nio.lsp.types.DefinitionParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.Definition|nio.lsp.types.DefinitionLink[]|nil result The result of the request
function LSPRequestClient.textDocument_definition(args, bufnr, opts) end

--- A request to resolve project-wide references for the symbol denoted
--- by the given text document position. The request's parameter is of
--- type [ReferenceParams](#ReferenceParams) the response is of type
--- [Location[]](#Location) or a Thenable that resolves to such.
---@async
---@param args nio.lsp.types.ReferenceParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.Location[]|nil result The result of the request
function LSPRequestClient.textDocument_references(args, bufnr, opts) end

--- Request to resolve a [DocumentHighlight](#DocumentHighlight) for a given
--- text document position. The request's parameter is of type [TextDocumentPosition]
--- (#TextDocumentPosition) the request response is of type [DocumentHighlight[]]
--- (#DocumentHighlight) or a Thenable that resolves to such.
---@async
---@param args nio.lsp.types.DocumentHighlightParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.DocumentHighlight[]|nil result The result of the request
function LSPRequestClient.textDocument_documentHighlight(args, bufnr, opts) end

--- A request to list all symbols found in a given text document. The request's
--- parameter is of type [TextDocumentIdentifier](#TextDocumentIdentifier) the
--- response is of type [SymbolInformation[]](#SymbolInformation) or a Thenable
--- that resolves to such.
---@async
---@param args nio.lsp.types.DocumentSymbolParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.SymbolInformation[]|nio.lsp.types.DocumentSymbol[]|nil result The result of the request
function LSPRequestClient.textDocument_documentSymbol(args, bufnr, opts) end

--- A request to provide commands for the given text document and range.
---@async
---@param args nio.lsp.types.CodeActionParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.Command|nio.lsp.types.CodeAction[]|nil result The result of the request
function LSPRequestClient.textDocument_codeAction(args, bufnr, opts) end

--- Request to resolve additional information for a given code action.The request's
--- parameter is of type [CodeAction](#CodeAction) the response
--- is of type [CodeAction](#CodeAction) or a Thenable that resolves to such.
---@async
---@param args nio.lsp.types.CodeAction Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.CodeAction|nil result The result of the request
function LSPRequestClient.codeAction_resolve(args, bufnr, opts) end

--- A request to list project-wide symbols matching the query string given
--- by the [WorkspaceSymbolParams](#WorkspaceSymbolParams). The response is
--- of type [SymbolInformation[]](#SymbolInformation) or a Thenable that
--- resolves to such.
---
--- @since 3.17.0 - support for WorkspaceSymbol in the returned data. Clients
---  need to advertise support for WorkspaceSymbols via the client capability
---  `workspace.symbol.resolveSupport`.
---
---@async
---@param args nio.lsp.types.WorkspaceSymbolParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.SymbolInformation[]|nio.lsp.types.WorkspaceSymbol[]|nil result The result of the request
function LSPRequestClient.workspace_symbol(args, bufnr, opts) end

--- A request to resolve the range inside the workspace
--- symbol's location.
---
--- @since 3.17.0
---@async
---@param args nio.lsp.types.WorkspaceSymbol Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.WorkspaceSymbol|nil result The result of the request
function LSPRequestClient.workspaceSymbol_resolve(args, bufnr, opts) end

--- A request to provide code lens for the given text document.
---@async
---@param args nio.lsp.types.CodeLensParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.CodeLens[]|nil result The result of the request
function LSPRequestClient.textDocument_codeLens(args, bufnr, opts) end

--- A request to resolve a command for a given code lens.
---@async
---@param args nio.lsp.types.CodeLens Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.CodeLens|nil result The result of the request
function LSPRequestClient.codeLens_resolve(args, bufnr, opts) end

--- A request to provide document links
---@async
---@param args nio.lsp.types.DocumentLinkParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.DocumentLink[]|nil result The result of the request
function LSPRequestClient.textDocument_documentLink(args, bufnr, opts) end

--- Request to resolve additional information for a given document link. The request's
--- parameter is of type [DocumentLink](#DocumentLink) the response
--- is of type [DocumentLink](#DocumentLink) or a Thenable that resolves to such.
---@async
---@param args nio.lsp.types.DocumentLink Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.DocumentLink|nil result The result of the request
function LSPRequestClient.documentLink_resolve(args, bufnr, opts) end

--- A request to to format a whole document.
---@async
---@param args nio.lsp.types.DocumentFormattingParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.TextEdit[]|nil result The result of the request
function LSPRequestClient.textDocument_formatting(args, bufnr, opts) end

--- A request to to format a range in a document.
---@async
---@param args nio.lsp.types.DocumentRangeFormattingParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.TextEdit[]|nil result The result of the request
function LSPRequestClient.textDocument_rangeFormatting(args, bufnr, opts) end

--- A request to format a document on type.
---@async
---@param args nio.lsp.types.DocumentOnTypeFormattingParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.TextEdit[]|nil result The result of the request
function LSPRequestClient.textDocument_onTypeFormatting(args, bufnr, opts) end

--- A request to rename a symbol.
---@async
---@param args nio.lsp.types.RenameParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.WorkspaceEdit|nil result The result of the request
function LSPRequestClient.textDocument_rename(args, bufnr, opts) end

--- A request to test and perform the setup necessary for a rename.
---
--- @since 3.16 - support for default behavior
---@async
---@param args nio.lsp.types.PrepareRenameParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.PrepareRenameResult|nil result The result of the request
function LSPRequestClient.textDocument_prepareRename(args, bufnr, opts) end

--- A request send from the client to the server to execute a command. The request might return
--- a workspace edit which the client will apply to the workspace.
---@async
---@param args nio.lsp.types.ExecuteCommandParams Arguments to the request
---@param bufnr integer? Buffer number (0 for current buffer)
---@param opts? nio.lsp.RequestOpts Options for the request handling
---@return nio.lsp.types.ResponseError|nil error The error object in case a request fails.
---@return nio.lsp.types.LSPAny|nil result The result of the request
function LSPRequestClient.workspace_executeCommand(args, bufnr, opts) end

---@class nio.lsp.NotifyClient
local LSPNotifyClient = {}

--- The `workspace/didChangeWorkspaceFolders` notification is sent from the client to the server when the workspace
--- folder configuration changes.
---@async
---@param args nio.lsp.types.DidChangeWorkspaceFoldersParams
function LSPNotifyClient.workspace_didChangeWorkspaceFolders(args) end

--- The `window/workDoneProgress/cancel` notification is sent from  the client to the server to cancel a progress
--- initiated on the server side.
---@async
---@param args nio.lsp.types.WorkDoneProgressCancelParams
function LSPNotifyClient.window_workDoneProgress_cancel(args) end

--- The did create files notification is sent from the client to the server when
--- files were created from within the client.
---
--- @since 3.16.0
---@async
---@param args nio.lsp.types.CreateFilesParams
function LSPNotifyClient.workspace_didCreateFiles(args) end

--- The did rename files notification is sent from the client to the server when
--- files were renamed from within the client.
---
--- @since 3.16.0
---@async
---@param args nio.lsp.types.RenameFilesParams
function LSPNotifyClient.workspace_didRenameFiles(args) end

--- The will delete files request is sent from the client to the server before files are actually
--- deleted as long as the deletion is triggered from within the client.
---
--- @since 3.16.0
---@async
---@param args nio.lsp.types.DeleteFilesParams
function LSPNotifyClient.workspace_didDeleteFiles(args) end

--- A notification sent when a notebook opens.
---
--- @since 3.17.0
---@async
---@param args nio.lsp.types.DidOpenNotebookDocumentParams
function LSPNotifyClient.notebookDocument_didOpen(args) end

---@async
---@param args nio.lsp.types.DidChangeNotebookDocumentParams
function LSPNotifyClient.notebookDocument_didChange(args) end

--- A notification sent when a notebook document is saved.
---
--- @since 3.17.0
---@async
---@param args nio.lsp.types.DidSaveNotebookDocumentParams
function LSPNotifyClient.notebookDocument_didSave(args) end

--- A notification sent when a notebook closes.
---
--- @since 3.17.0
---@async
---@param args nio.lsp.types.DidCloseNotebookDocumentParams
function LSPNotifyClient.notebookDocument_didClose(args) end

--- The initialized notification is sent from the client to the
--- server after the client is fully initialized and the server
--- is allowed to send requests from the server to the client.
---@async
---@param args nio.lsp.types.InitializedParams
function LSPNotifyClient.initialized(args) end

--- The exit event is sent from the client to the server to
--- ask the server to exit its process.
---@async
--- The configuration change notification is sent from the client to the server
--- when the client's configuration has changed. The notification contains
--- the changed configuration as defined by the language client.
---@async
---@param args nio.lsp.types.DidChangeConfigurationParams
function LSPNotifyClient.workspace_didChangeConfiguration(args) end

--- The document open notification is sent from the client to the server to signal
--- newly opened text documents. The document's truth is now managed by the client
--- and the server must not try to read the document's truth using the document's
--- uri. Open in this sense means it is managed by the client. It doesn't necessarily
--- mean that its content is presented in an editor. An open notification must not
--- be sent more than once without a corresponding close notification send before.
--- This means open and close notification must be balanced and the max open count
--- is one.
---@async
---@param args nio.lsp.types.DidOpenTextDocumentParams
function LSPNotifyClient.textDocument_didOpen(args) end

--- The document change notification is sent from the client to the server to signal
--- changes to a text document.
---@async
---@param args nio.lsp.types.DidChangeTextDocumentParams
function LSPNotifyClient.textDocument_didChange(args) end

--- The document close notification is sent from the client to the server when
--- the document got closed in the client. The document's truth now exists where
--- the document's uri points to (e.g. if the document's uri is a file uri the
--- truth now exists on disk). As with the open notification the close notification
--- is about managing the document's content. Receiving a close notification
--- doesn't mean that the document was open in an editor before. A close
--- notification requires a previous open notification to be sent.
---@async
---@param args nio.lsp.types.DidCloseTextDocumentParams
function LSPNotifyClient.textDocument_didClose(args) end

--- The document save notification is sent from the client to the server when
--- the document got saved in the client.
---@async
---@param args nio.lsp.types.DidSaveTextDocumentParams
function LSPNotifyClient.textDocument_didSave(args) end

--- A document will save notification is sent from the client to the server before
--- the document is actually saved.
---@async
---@param args nio.lsp.types.WillSaveTextDocumentParams
function LSPNotifyClient.textDocument_willSave(args) end

--- The watched files notification is sent from the client to the server when
--- the client detects changes to file watched by the language client.
---@async
---@param args nio.lsp.types.DidChangeWatchedFilesParams
function LSPNotifyClient.workspace_didChangeWatchedFiles(args) end

---@async
---@param args nio.lsp.types.SetTraceParams
function LSPNotifyClient.__setTrace(args) end

---@async
---@param args nio.lsp.types.CancelParams
function LSPNotifyClient.__cancelRequest(args) end

---@async
---@param args nio.lsp.types.ProgressParams
function LSPNotifyClient.__progress(args) end

---@alias nio.lsp.types.URI string
---@alias nio.lsp.types.DocumentUri string

--- The result returned from the apply workspace edit request.
---
--- @since 3.17 renamed from ApplyWorkspaceEditResponse
---@class nio.lsp.types.ApplyWorkspaceEditResult
---@field applied boolean Indicates whether the edit was applied or not.
---@field failureReason? string An optional textual description for why the edit was not applied. This may be used by the server for diagnostic logging or to provide a suitable error for a request that triggered the edit.
---@field failedChange? integer Depending on the client's failure handling strategy `failedChange` might contain the index of the change that failed. This property is only available if the client signals a `failureHandlingStrategy` in its client capabilities.

--- The parameters passed via a apply workspace edit request.
---@class nio.lsp.types.ApplyWorkspaceEditParams
---@field label? string An optional label of the workspace edit. This label is presented in the user interface for example on an undo stack to undo the workspace edit.
---@field edit nio.lsp.types.WorkspaceEdit The edits to apply.
--- A pattern kind describing if a glob pattern matches a file a folder or
--- both.
---
--- @since 3.16.0
---@alias nio.lsp.types.FileOperationPatternKind "file"|"folder"

--- The parameters of a `workspace/didChangeWorkspaceFolders` notification.
---@class nio.lsp.types.DidChangeWorkspaceFoldersParams
---@field event nio.lsp.types.WorkspaceFoldersChangeEvent The actual workspace folder change event.

--- Defines the capabilities provided by a language
--- server.
---@class nio.lsp.types.ServerCapabilities
---@field positionEncoding? nio.lsp.types.PositionEncodingKind The position encoding the server picked from the encodings offered by the client via the client capability `general.positionEncodings`.  If the client didn't provide any position encodings the only valid value that a server can return is 'utf-16'.  If omitted it defaults to 'utf-16'.  @since 3.17.0
---@field textDocumentSync? nio.lsp.types.TextDocumentSyncOptions|nio.lsp.types.TextDocumentSyncKind Defines how text documents are synced. Is either a detailed structure defining each notification or for backwards compatibility the TextDocumentSyncKind number.
---@field notebookDocumentSync? nio.lsp.types.NotebookDocumentSyncOptions|nio.lsp.types.NotebookDocumentSyncRegistrationOptions Defines how notebook documents are synced.  @since 3.17.0
---@field completionProvider? nio.lsp.types.CompletionOptions The server provides completion support.
---@field hoverProvider? boolean|nio.lsp.types.HoverOptions The server provides hover support.
---@field signatureHelpProvider? nio.lsp.types.SignatureHelpOptions The server provides signature help support.
---@field declarationProvider? boolean|nio.lsp.types.DeclarationOptions|nio.lsp.types.DeclarationRegistrationOptions The server provides Goto Declaration support.
---@field definitionProvider? boolean|nio.lsp.types.DefinitionOptions The server provides goto definition support.
---@field typeDefinitionProvider? boolean|nio.lsp.types.TypeDefinitionOptions|nio.lsp.types.TypeDefinitionRegistrationOptions The server provides Goto Type Definition support.
---@field implementationProvider? boolean|nio.lsp.types.ImplementationOptions|nio.lsp.types.ImplementationRegistrationOptions The server provides Goto Implementation support.
---@field referencesProvider? boolean|nio.lsp.types.ReferenceOptions The server provides find references support.
---@field documentHighlightProvider? boolean|nio.lsp.types.DocumentHighlightOptions The server provides document highlight support.
---@field documentSymbolProvider? boolean|nio.lsp.types.DocumentSymbolOptions The server provides document symbol support.
---@field codeActionProvider? boolean|nio.lsp.types.CodeActionOptions The server provides code actions. CodeActionOptions may only be specified if the client states that it supports `codeActionLiteralSupport` in its initial `initialize` request.
---@field codeLensProvider? nio.lsp.types.CodeLensOptions The server provides code lens.
---@field documentLinkProvider? nio.lsp.types.DocumentLinkOptions The server provides document link support.
---@field colorProvider? boolean|nio.lsp.types.DocumentColorOptions|nio.lsp.types.DocumentColorRegistrationOptions The server provides color provider support.
---@field workspaceSymbolProvider? boolean|nio.lsp.types.WorkspaceSymbolOptions The server provides workspace symbol support.
---@field documentFormattingProvider? boolean|nio.lsp.types.DocumentFormattingOptions The server provides document formatting.
---@field documentRangeFormattingProvider? boolean|nio.lsp.types.DocumentRangeFormattingOptions The server provides document range formatting.
---@field documentOnTypeFormattingProvider? nio.lsp.types.DocumentOnTypeFormattingOptions The server provides document formatting on typing.
---@field renameProvider? boolean|nio.lsp.types.RenameOptions The server provides rename support. RenameOptions may only be specified if the client states that it supports `prepareSupport` in its initial `initialize` request.
---@field foldingRangeProvider? boolean|nio.lsp.types.FoldingRangeOptions|nio.lsp.types.FoldingRangeRegistrationOptions The server provides folding provider support.
---@field selectionRangeProvider? boolean|nio.lsp.types.SelectionRangeOptions|nio.lsp.types.SelectionRangeRegistrationOptions The server provides selection range support.
---@field executeCommandProvider? nio.lsp.types.ExecuteCommandOptions The server provides execute command support.
---@field callHierarchyProvider? boolean|nio.lsp.types.CallHierarchyOptions|nio.lsp.types.CallHierarchyRegistrationOptions The server provides call hierarchy support.  @since 3.16.0
---@field linkedEditingRangeProvider? boolean|nio.lsp.types.LinkedEditingRangeOptions|nio.lsp.types.LinkedEditingRangeRegistrationOptions The server provides linked editing range support.  @since 3.16.0
---@field semanticTokensProvider? nio.lsp.types.SemanticTokensOptions|nio.lsp.types.SemanticTokensRegistrationOptions The server provides semantic tokens support.  @since 3.16.0
---@field monikerProvider? boolean|nio.lsp.types.MonikerOptions|nio.lsp.types.MonikerRegistrationOptions The server provides moniker support.  @since 3.16.0
---@field typeHierarchyProvider? boolean|nio.lsp.types.TypeHierarchyOptions|nio.lsp.types.TypeHierarchyRegistrationOptions The server provides type hierarchy support.  @since 3.17.0
---@field inlineValueProvider? boolean|nio.lsp.types.InlineValueOptions|nio.lsp.types.InlineValueRegistrationOptions The server provides inline values.  @since 3.17.0
---@field inlayHintProvider? boolean|nio.lsp.types.InlayHintOptions|nio.lsp.types.InlayHintRegistrationOptions The server provides inlay hints.  @since 3.17.0
---@field diagnosticProvider? nio.lsp.types.DiagnosticOptions|nio.lsp.types.DiagnosticRegistrationOptions The server has support for pull model diagnostics.  @since 3.17.0
---@field workspace? nio.lsp.types.Structure0 Workspace specific server capabilities.
---@field experimental? nio.lsp.types.LSPAny Experimental server capabilities.

---@class nio.lsp.types.WorkDoneProgressCancelParams
---@field token nio.lsp.types.ProgressToken The token to be used to report progress.

--- A full document diagnostic report for a workspace diagnostic result.
---
--- @since 3.17.0
---@class nio.lsp.types.WorkspaceFullDocumentDiagnosticReport : nio.lsp.types.FullDocumentDiagnosticReport
---@field uri nio.lsp.types.DocumentUri The URI for which diagnostic information is reported.
---@field version integer|nil The version number for which the diagnostics are reported. If the document is not marked as open `null` can be provided.

--- An unchanged document diagnostic report for a workspace diagnostic result.
---
--- @since 3.17.0
---@class nio.lsp.types.WorkspaceUnchangedDocumentDiagnosticReport : nio.lsp.types.UnchangedDocumentDiagnosticReport
---@field uri nio.lsp.types.DocumentUri The URI for which diagnostic information is reported.
---@field version integer|nil The version number for which the diagnostics are reported. If the document is not marked as open `null` can be provided.
--- A notebook cell kind.
---
--- @since 3.17.0
---@alias nio.lsp.types.NotebookCellKind 1|2

--- The params sent in an open notebook document notification.
---
--- @since 3.17.0
---@class nio.lsp.types.DidOpenNotebookDocumentParams
---@field notebookDocument nio.lsp.types.NotebookDocument The notebook document that got opened.
---@field cellTextDocuments nio.lsp.types.TextDocumentItem[] The text documents that represent the content of a notebook cell.

---@class nio.lsp.types.ExecutionSummary
---@field executionOrder integer A strict monotonically increasing value indicating the execution order of a cell inside a notebook.
---@field success? boolean Whether the execution was successful or not if known by the client.

--- The params sent in a change notebook document notification.
---
--- @since 3.17.0
---@class nio.lsp.types.DidChangeNotebookDocumentParams
---@field notebookDocument nio.lsp.types.VersionedNotebookDocumentIdentifier The notebook document that did change. The version number points to the version after all provided changes have been applied. If only the text document content of a cell changes the notebook version doesn't necessarily have to change.
---@field change nio.lsp.types.NotebookDocumentChangeEvent The actual changes to the notebook document.  The changes describe single state changes to the notebook document. So if there are two changes c1 (at array index 0) and c2 (at array index 1) for a notebook in state S then c1 moves the notebook from S to S' and c2 from S' to S''. So c1 is computed on the state S and c2 is computed on the state S'.  To mirror the content of a notebook using change events use the following approach: - start with the same initial content - apply the 'notebookDocument/didChange' notifications in the order you receive them. - apply the `NotebookChangeEvent`s in a single notification in the order   you receive them.

--- The params sent in a save notebook document notification.
---
--- @since 3.17.0
---@class nio.lsp.types.DidSaveNotebookDocumentParams
---@field notebookDocument nio.lsp.types.NotebookDocumentIdentifier The notebook document that got saved.

--- The params sent in a close notebook document notification.
---
--- @since 3.17.0
---@class nio.lsp.types.DidCloseNotebookDocumentParams
---@field notebookDocument nio.lsp.types.NotebookDocumentIdentifier The notebook document that got closed.
---@field cellTextDocuments nio.lsp.types.TextDocumentIdentifier[] The text documents that represent the content of a notebook cell that got closed.

--- A text document identifier to denote a specific version of a text document.
---@class nio.lsp.types.VersionedTextDocumentIdentifier : nio.lsp.types.TextDocumentIdentifier
---@field version integer The version number of this document.

---@class nio.lsp.types.InitializedParams

--- Text document specific client capabilities.
---@class nio.lsp.types.TextDocumentClientCapabilities
---@field synchronization? nio.lsp.types.TextDocumentSyncClientCapabilities Defines which synchronization capabilities the client supports.
---@field completion? nio.lsp.types.CompletionClientCapabilities Capabilities specific to the `textDocument/completion` request.
---@field hover? nio.lsp.types.HoverClientCapabilities Capabilities specific to the `textDocument/hover` request.
---@field signatureHelp? nio.lsp.types.SignatureHelpClientCapabilities Capabilities specific to the `textDocument/signatureHelp` request.
---@field declaration? nio.lsp.types.DeclarationClientCapabilities Capabilities specific to the `textDocument/declaration` request.  @since 3.14.0
---@field definition? nio.lsp.types.DefinitionClientCapabilities Capabilities specific to the `textDocument/definition` request.
---@field typeDefinition? nio.lsp.types.TypeDefinitionClientCapabilities Capabilities specific to the `textDocument/typeDefinition` request.  @since 3.6.0
---@field implementation? nio.lsp.types.ImplementationClientCapabilities Capabilities specific to the `textDocument/implementation` request.  @since 3.6.0
---@field references? nio.lsp.types.ReferenceClientCapabilities Capabilities specific to the `textDocument/references` request.
---@field documentHighlight? nio.lsp.types.DocumentHighlightClientCapabilities Capabilities specific to the `textDocument/documentHighlight` request.
---@field documentSymbol? nio.lsp.types.DocumentSymbolClientCapabilities Capabilities specific to the `textDocument/documentSymbol` request.
---@field codeAction? nio.lsp.types.CodeActionClientCapabilities Capabilities specific to the `textDocument/codeAction` request.
---@field codeLens? nio.lsp.types.CodeLensClientCapabilities Capabilities specific to the `textDocument/codeLens` request.
---@field documentLink? nio.lsp.types.DocumentLinkClientCapabilities Capabilities specific to the `textDocument/documentLink` request.
---@field colorProvider? nio.lsp.types.DocumentColorClientCapabilities Capabilities specific to the `textDocument/documentColor` and the `textDocument/colorPresentation` request.  @since 3.6.0
---@field formatting? nio.lsp.types.DocumentFormattingClientCapabilities Capabilities specific to the `textDocument/formatting` request.
---@field rangeFormatting? nio.lsp.types.DocumentRangeFormattingClientCapabilities Capabilities specific to the `textDocument/rangeFormatting` request.
---@field onTypeFormatting? nio.lsp.types.DocumentOnTypeFormattingClientCapabilities Capabilities specific to the `textDocument/onTypeFormatting` request.
---@field rename? nio.lsp.types.RenameClientCapabilities Capabilities specific to the `textDocument/rename` request.
---@field foldingRange? nio.lsp.types.FoldingRangeClientCapabilities Capabilities specific to the `textDocument/foldingRange` request.  @since 3.10.0
---@field selectionRange? nio.lsp.types.SelectionRangeClientCapabilities Capabilities specific to the `textDocument/selectionRange` request.  @since 3.15.0
---@field publishDiagnostics? nio.lsp.types.PublishDiagnosticsClientCapabilities Capabilities specific to the `textDocument/publishDiagnostics` notification.
---@field callHierarchy? nio.lsp.types.CallHierarchyClientCapabilities Capabilities specific to the various call hierarchy requests.  @since 3.16.0
---@field semanticTokens? nio.lsp.types.SemanticTokensClientCapabilities Capabilities specific to the various semantic token request.  @since 3.16.0
---@field linkedEditingRange? nio.lsp.types.LinkedEditingRangeClientCapabilities Capabilities specific to the `textDocument/linkedEditingRange` request.  @since 3.16.0
---@field moniker? nio.lsp.types.MonikerClientCapabilities Client capabilities specific to the `textDocument/moniker` request.  @since 3.16.0
---@field typeHierarchy? nio.lsp.types.TypeHierarchyClientCapabilities Capabilities specific to the various type hierarchy requests.  @since 3.17.0
---@field inlineValue? nio.lsp.types.InlineValueClientCapabilities Capabilities specific to the `textDocument/inlineValue` request.  @since 3.17.0
---@field inlayHint? nio.lsp.types.InlayHintClientCapabilities Capabilities specific to the `textDocument/inlayHint` request.  @since 3.17.0
---@field diagnostic? nio.lsp.types.DiagnosticClientCapabilities Capabilities specific to the diagnostic pull model.  @since 3.17.0

---@class nio.lsp.types.Structure3
---@field labelDetailsSupport? boolean The server has support for completion item label details (see also `CompletionItemLabelDetails`) when receiving a completion item in a resolve call.  @since 3.17.0

--- The parameters of a change configuration notification.
---@class nio.lsp.types.DidChangeConfigurationParams
---@field settings nio.lsp.types.LSPAny The actual changed settings

---@class nio.lsp.types.DidChangeConfigurationRegistrationOptions
---@field section? string|string[]

---@class nio.lsp.types.WindowClientCapabilities
---@field workDoneProgress? boolean It indicates whether the client supports server initiated progress using the `window/workDoneProgress/create` request.  The capability also controls Whether client supports handling of progress notifications. If set servers are allowed to report a `workDoneProgress` property in the request specific server capabilities.  @since 3.15.0
---@field showMessage? nio.lsp.types.ShowMessageRequestClientCapabilities Capabilities specific to the showMessage request.  @since 3.16.0
---@field showDocument? nio.lsp.types.ShowDocumentClientCapabilities Capabilities specific to the showDocument request.  @since 3.16.0

--- The parameters of a notification message.
---@class nio.lsp.types.ShowMessageParams
---@field type nio.lsp.types.MessageType The message type. See {@link MessageType}
---@field message string The actual message.

--- The log message parameters.
---@class nio.lsp.types.LogMessageParams
---@field type nio.lsp.types.MessageType The message type. See {@link MessageType}
---@field message string The actual message.

---@class nio.lsp.types.Structure4
---@field language string
---@field value string

--- The parameters sent in an open text document notification
---@class nio.lsp.types.DidOpenTextDocumentParams
---@field textDocument nio.lsp.types.TextDocumentItem The document that was opened.

--- The change text document notification's parameters.
---@class nio.lsp.types.DidChangeTextDocumentParams
---@field textDocument nio.lsp.types.VersionedTextDocumentIdentifier The document that did change. The version number points to the version after all provided content changes have been applied.
---@field contentChanges nio.lsp.types.TextDocumentContentChangeEvent[] The actual content changes. The content changes describe single state changes to the document. So if there are two content changes c1 (at array index 0) and c2 (at array index 1) for a document in state S then c1 moves the document from S to S' and c2 from S' to S''. So c1 is computed on the state S and c2 is computed on the state S'.  To mirror the content of a document using change events use the following approach: - start with the same initial content - apply the 'textDocument/didChange' notifications in the order you receive them. - apply the `TextDocumentContentChangeEvent`s in a single notification in the order   you receive them.

--- Describe options to be used when registered for text document change events.
---@class nio.lsp.types.TextDocumentChangeRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions
---@field syncKind nio.lsp.types.TextDocumentSyncKind How documents are synced to the server.

--- The parameters sent in a close text document notification
---@class nio.lsp.types.DidCloseTextDocumentParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The document that was closed.

--- The parameters sent in a save text document notification
---@class nio.lsp.types.DidSaveTextDocumentParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The document that was saved.
---@field text? string Optional the content when saved. Depends on the includeText value when the save notification was requested.

--- Save registration options.
---@class nio.lsp.types.TextDocumentSaveRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.SaveOptions

--- Client Capabilities for a [DocumentHighlightRequest](#DocumentHighlightRequest).
---@class nio.lsp.types.DocumentHighlightClientCapabilities
---@field dynamicRegistration? boolean Whether document highlight supports dynamic registration.

---@class nio.lsp.types.Structure36
---@field notebookType string The type of the enclosing notebook.
---@field scheme? string A Uri [scheme](#Uri.scheme), like `file` or `untitled`.
---@field pattern? string A glob pattern.

--- The watched files change notification's parameters.
---@class nio.lsp.types.DidChangeWatchedFilesParams
---@field changes nio.lsp.types.FileEvent[] The actual file events.

--- Describe options to be used when registered for text document change events.
---@class nio.lsp.types.DidChangeWatchedFilesRegistrationOptions
---@field watchers nio.lsp.types.FileSystemWatcher[] The watchers to register.

--- The Client Capabilities of a [CodeActionRequest](#CodeActionRequest).
---@class nio.lsp.types.CodeActionClientCapabilities
---@field dynamicRegistration? boolean Whether code action supports dynamic registration.
---@field codeActionLiteralSupport? nio.lsp.types.Structure1 The client support code action literals of type `CodeAction` as a valid response of the `textDocument/codeAction` request. If the property is not set the request can only return `Command` literals.  @since 3.8.0
---@field isPreferredSupport? boolean Whether code action supports the `isPreferred` property.  @since 3.15.0
---@field disabledSupport? boolean Whether code action supports the `disabled` property.  @since 3.16.0
---@field dataSupport? boolean Whether code action supports the `data` property which is preserved between a `textDocument/codeAction` and a `codeAction/resolve` request.  @since 3.16.0
---@field resolveSupport? nio.lsp.types.Structure2 Whether the client supports resolving additional code action properties via a separate `codeAction/resolve` request.  @since 3.16.0
---@field honorsChangeAnnotations? boolean Whether the client honors the change annotations in text edits and resource operations returned via the `CodeAction#edit` property by for example presenting the workspace edit in the user interface and asking for confirmation.  @since 3.16.0

--- The publish diagnostic notification's parameters.
---@class nio.lsp.types.PublishDiagnosticsParams
---@field uri nio.lsp.types.DocumentUri The URI for which diagnostic information is reported.
---@field version? integer Optional the version number of the document the diagnostics are published for.  @since 3.15.0
---@field diagnostics nio.lsp.types.Diagnostic[] An array of diagnostic information items.

--- Position in a text document expressed as zero-based line and character
--- offset. Prior to 3.17 the offsets were always based on a UTF-16 string
--- representation. So a string of the form `a𐐀b` the character offset of the
--- character `a` is 0, the character offset of `𐐀` is 1 and the character
--- offset of b is 3 since `𐐀` is represented using two code units in UTF-16.
--- Since 3.17 clients and servers can agree on a different string encoding
--- representation (e.g. UTF-8). The client announces it's supported encoding
--- via the client capability [`general.positionEncodings`](#clientCapabilities).
--- The value is an array of position encodings the client supports, with
--- decreasing preference (e.g. the encoding at index `0` is the most preferred
--- one). To stay backwards compatible the only mandatory encoding is UTF-16
--- represented via the string `utf-16`. The server can pick one of the
--- encodings offered by the client and signals that encoding back to the
--- client via the initialize result's property
--- [`capabilities.positionEncoding`](#serverCapabilities). If the string value
--- `utf-16` is missing from the client's capability `general.positionEncodings`
--- servers can safely assume that the client supports UTF-16. If the server
--- omits the position encoding in its initialize result the encoding defaults
--- to the string value `utf-16`. Implementation considerations: since the
--- conversion from one encoding into another requires the content of the
--- file / line the conversion is best done where the file is read which is
--- usually on the server side.
---
--- Positions are line end character agnostic. So you can not specify a position
--- that denotes `\r|\n` or `\n|` where `|` represents the character offset.
---
--- @since 3.17.0 - support for negotiated position encoding.
---@class nio.lsp.types.Position
---@field line integer Line position in a document (zero-based).  If a line number is greater than the number of lines in a document, it defaults back to the number of lines in the document. If a line number is negative, it defaults to 0.
---@field character integer Character offset on a line in a document (zero-based).  The meaning of this offset is determined by the negotiated `PositionEncodingKind`.  If the character value is greater than the line length it defaults back to the line length.
--- Completion item tags are extra annotations that tweak the rendering of a completion
--- item.
---
--- @since 3.15.0
---@alias nio.lsp.types.CompletionItemTag 1

---@class nio.lsp.types.SetTraceParams
---@field value nio.lsp.types.TraceValues

--- Contains additional information about the context in which a completion request is triggered.
---@class nio.lsp.types.CompletionContext
---@field triggerKind nio.lsp.types.CompletionTriggerKind How the completion was triggered.
---@field triggerCharacter? string The trigger character (a single character) that has trigger code complete. Is undefined if `triggerKind !== CompletionTriggerKind.TriggerCharacter`

---@class nio.lsp.types.LogTraceParams
---@field message string
---@field verbose? string

---@class nio.lsp.types.CancelParams
---@field id integer|string The request id to cancel.

---@class nio.lsp.types.ProgressParams
---@field token nio.lsp.types.ProgressToken The progress token provided by the client or server.
---@field value nio.lsp.types.LSPAny The progress data.

--- A parameter literal used in requests to pass a text document and a position inside that
--- document.
---@class nio.lsp.types.TextDocumentPositionParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The text document.
---@field position nio.lsp.types.Position The position inside the text document.

---@class nio.lsp.types.WorkDoneProgressParams
---@field workDoneToken? nio.lsp.types.ProgressToken An optional token that a server can use to report work done progress.

---@class nio.lsp.types.ImplementationOptions : nio.lsp.types.WorkDoneProgressOptions

--- Static registration options to be returned in the initialize
--- request.
---@class nio.lsp.types.StaticRegistrationOptions
---@field id? string The id used to register the request. The id can be used to deregister the request again. See also Registration#id.

---@class nio.lsp.types.TypeDefinitionOptions : nio.lsp.types.WorkDoneProgressOptions

--- The workspace folder change event.
---@class nio.lsp.types.WorkspaceFoldersChangeEvent
---@field added nio.lsp.types.WorkspaceFolder[] The array of added workspace folders
---@field removed nio.lsp.types.WorkspaceFolder[] The array of the removed workspace folders

---@class nio.lsp.types.ConfigurationItem
---@field scopeUri? string The scope to get the configuration section for.
---@field section? string The configuration section asked for.

--- A special text edit to provide an insert and a replace operation.
---
--- @since 3.16.0
---@class nio.lsp.types.InsertReplaceEdit
---@field newText string The string to be inserted.
---@field insert nio.lsp.types.Range The range if the insert is requested
---@field replace nio.lsp.types.Range The range if the replace is requested.

---@class nio.lsp.types.Structure5

--- Completion options.
---@class nio.lsp.types.CompletionOptions : nio.lsp.types.WorkDoneProgressOptions
---@field triggerCharacters? string[] Most tools trigger completion request automatically without explicitly requesting it using a keyboard shortcut (e.g. Ctrl+Space). Typically they do so when the user starts to type an identifier. For example if the user types `c` in a JavaScript file code complete will automatically pop up present `console` besides others as a completion item. Characters that make up identifiers don't need to be listed here.  If code complete should automatically be trigger on characters not being valid inside an identifier (for example `.` in JavaScript) list them in `triggerCharacters`.
---@field allCommitCharacters? string[] The list of all possible characters that commit a completion. This field can be used if clients don't support individual commit characters per completion item. See `ClientCapabilities.textDocument.completion.completionItem.commitCharactersSupport`  If a server provides both `allCommitCharacters` and commit characters on an individual completion item the ones on the completion item win.  @since 3.2.0
---@field resolveProvider? boolean The server provides support to resolve additional information for a completion item.
---@field completionItem? nio.lsp.types.Structure3 The server supports the following `CompletionItem` specific capabilities.  @since 3.17.0
---@alias nio.lsp.types.MarkedString string|nio.lsp.types.Structure4
---@alias nio.lsp.types.PrepareSupportDefaultBehavior 1

--- Hover options.
---@class nio.lsp.types.HoverOptions : nio.lsp.types.WorkDoneProgressOptions

--- Additional information about the context in which a signature help request was triggered.
---
--- @since 3.15.0
---@class nio.lsp.types.SignatureHelpContext
---@field triggerKind nio.lsp.types.SignatureHelpTriggerKind Action that caused signature help to be triggered.
---@field triggerCharacter? string Character that caused signature help to be triggered.  This is undefined when `triggerKind !== SignatureHelpTriggerKind.TriggerCharacter`
---@field isRetrigger boolean `true` if signature help was already showing when it was triggered.  Retriggers occurs when the signature help is already active and can be caused by actions such as typing a trigger character, a cursor move, or document content changes.
---@field activeSignatureHelp? nio.lsp.types.SignatureHelp The currently active `SignatureHelp`.  The `activeSignatureHelp` has its `SignatureHelp.activeSignature` field updated based on the user navigating through available signatures.

--- Represents the signature of something callable. A signature
--- can have a label, like a function-name, a doc-comment, and
--- a set of parameters.
---@class nio.lsp.types.SignatureInformation
---@field label string The label of this signature. Will be shown in the UI.
---@field documentation? string|nio.lsp.types.MarkupContent The human-readable doc-comment of this signature. Will be shown in the UI but can be omitted.
---@field parameters? nio.lsp.types.ParameterInformation[] The parameters of this signature.
---@field activeParameter? integer The index of the active parameter.  If provided, this is used in place of `SignatureHelp.activeParameter`.  @since 3.16.0

--- Server Capabilities for a [SignatureHelpRequest](#SignatureHelpRequest).
---@class nio.lsp.types.SignatureHelpOptions : nio.lsp.types.WorkDoneProgressOptions
---@field triggerCharacters? string[] List of characters that trigger signature help automatically.
---@field retriggerCharacters? string[] List of characters that re-trigger signature help.  These trigger characters are only active when signature help is already showing. All trigger characters are also counted as re-trigger characters.  @since 3.15.0

--- Server Capabilities for a [DefinitionRequest](#DefinitionRequest).
---@class nio.lsp.types.DefinitionOptions : nio.lsp.types.WorkDoneProgressOptions

--- Value-object that contains additional information when
--- requesting references.
---@class nio.lsp.types.ReferenceContext
---@field includeDeclaration boolean Include the declaration of the current symbol.

--- Reference options.
---@class nio.lsp.types.ReferenceOptions : nio.lsp.types.WorkDoneProgressOptions

---@class nio.lsp.types.Structure15
---@field language string A language id, like `typescript`.
---@field scheme? string A Uri [scheme](#Uri.scheme), like `file` or `untitled`.
---@field pattern? string A glob pattern, like `*.{ts,js}`.

---@class nio.lsp.types.WorkDoneProgressReport
---@field kind 'report'
---@field cancellable? boolean Controls enablement state of a cancel button.  Clients that don't support cancellation or don't support controlling the button's enablement state are allowed to ignore the property.
---@field message? string Optional, more detailed associated progress message. Contains complementary information to the `title`.  Examples: "3/25 files", "project/src/module2", "node_modules/some_dep". If unset, the previous progress message (if any) is still valid.
---@field percentage? integer Optional progress percentage to display (value 100 is considered 100%). If not provided infinite progress is assumed and clients are allowed to ignore the `percentage` value in subsequent in report notifications.  The value should be steadily rising. Clients are free to ignore values that are not following this rule. The value range is [0, 100]

--- Provider options for a [DocumentHighlightRequest](#DocumentHighlightRequest).
---@class nio.lsp.types.DocumentHighlightOptions : nio.lsp.types.WorkDoneProgressOptions

---@class nio.lsp.types.WorkDoneProgressEnd
---@field kind 'end'
---@field message? string Optional, a final message indicating to for example indicate the outcome of the operation.
---@alias nio.lsp.types.TokenFormat "relative"

---@alias nio.lsp.types.TraceValues "off"|"messages"|"verbose"

--- A base for all symbol information.
---@class nio.lsp.types.BaseSymbolInformation
---@field name string The name of this symbol.
---@field kind nio.lsp.types.SymbolKind The kind of this symbol.
---@field tags? nio.lsp.types.SymbolTag[] Tags for this symbol.  @since 3.16.0
---@field containerName? string The name of the symbol containing this symbol. This information is for user interface purposes (e.g. to render a qualifier in the user interface if necessary). It can't be used to re-infer a hierarchy for the document symbols.

---@class nio.lsp.types.Structure32
---@field valueSet nio.lsp.types.DiagnosticTag[] The tags supported by the client.

--- Represents the connection of two locations. Provides additional metadata over normal [locations](#Location),
--- including an origin range.
---@class nio.lsp.types.LocationLink
---@field originSelectionRange? nio.lsp.types.Range Span of the origin of this link.  Used as the underlined span for mouse interaction. Defaults to the word range at the definition position.
---@field targetUri nio.lsp.types.DocumentUri The target resource identifier of this link.
---@field targetRange nio.lsp.types.Range The full target range of this link. If the target for example is a symbol then target range is the range enclosing this symbol not including leading/trailing whitespace but everything else like comments. This information is typically used to highlight the range in the editor.
---@field targetSelectionRange nio.lsp.types.Range The range that should be selected and revealed when this link is being followed, e.g the name of a function. Must be contained by the `targetRange`. See also `DocumentSymbol#range`

---@class nio.lsp.types.Structure12
---@field itemDefaults? string[] The client supports the following itemDefaults on a completion list.  The value lists the supported property names of the `CompletionList.itemDefaults` object. If omitted no properties are supported.  @since 3.17.0

--- Provider options for a [DocumentSymbolRequest](#DocumentSymbolRequest).
---@class nio.lsp.types.DocumentSymbolOptions : nio.lsp.types.WorkDoneProgressOptions
---@field label? string A human-readable string that is shown when multiple outlines trees are shown for the same document.  @since 3.16.0

---@class nio.lsp.types.Structure18
---@field language string

--- Contains additional diagnostic information about the context in which
--- a [code action](#CodeActionProvider.provideCodeActions) is run.
---@class nio.lsp.types.CodeActionContext
---@field diagnostics nio.lsp.types.Diagnostic[] An array of diagnostics known on the client side overlapping the range provided to the `textDocument/codeAction` request. They are provided so that the server knows which errors are currently presented to the user for the given range. There is no guarantee that these accurately reflect the error state of the resource. The primary parameter to compute code actions is the provided range.
---@field only? nio.lsp.types.CodeActionKind[] Requested kind of actions to return.  Actions not of this kind are filtered out by the client before being shown. So servers can omit computing them.
---@field triggerKind? nio.lsp.types.CodeActionTriggerKind The reason why code actions were requested.  @since 3.17.0

--- @since 3.16.0
---@class nio.lsp.types.SemanticTokensWorkspaceClientCapabilities
---@field refreshSupport? boolean Whether the client implementation supports a refresh request sent from the server to the client.  Note that this event is global and will force the client to refresh all semantic tokens currently shown. It should be used with absolute care and is useful for situation where a server for example detects a project wide change that requires such a calculation.

--- @since 3.16.0
---@class nio.lsp.types.CodeLensWorkspaceClientCapabilities
---@field refreshSupport? boolean Whether the client implementation supports a refresh request sent from the server to the client.  Note that this event is global and will force the client to refresh all code lenses currently shown. It should be used with absolute care and is useful for situation where a server for example detect a project wide change that requires such a calculation.

--- Capabilities relating to events from file operations by the user in the client.
---
--- These events do not come from the file system, they come from user operations
--- like renaming a file in the UI.
---
--- @since 3.16.0
---@class nio.lsp.types.FileOperationClientCapabilities
---@field dynamicRegistration? boolean Whether the client supports dynamic registration for file requests/notifications.
---@field didCreate? boolean The client has support for sending didCreateFiles notifications.
---@field willCreate? boolean The client has support for sending willCreateFiles requests.
---@field didRename? boolean The client has support for sending didRenameFiles notifications.
---@field willRename? boolean The client has support for sending willRenameFiles requests.
---@field didDelete? boolean The client has support for sending didDeleteFiles notifications.
---@field willDelete? boolean The client has support for sending willDeleteFiles requests.

--- Client workspace capabilities specific to inline values.
---
--- @since 3.17.0
---@class nio.lsp.types.InlineValueWorkspaceClientCapabilities
---@field refreshSupport? boolean Whether the client implementation supports a refresh request sent from the server to the client.  Note that this event is global and will force the client to refresh all inline values currently shown. It should be used with absolute care and is useful for situation where a server for example detects a project wide change that requires such a calculation.

--- Client workspace capabilities specific to inlay hints.
---
--- @since 3.17.0
---@class nio.lsp.types.InlayHintWorkspaceClientCapabilities
---@field refreshSupport? boolean Whether the client implementation supports a refresh request sent from the server to the client.  Note that this event is global and will force the client to refresh all inlay hints currently shown. It should be used with absolute care and is useful for situation where a server for example detects a project wide change that requires such a calculation.

--- Workspace client capabilities specific to diagnostic pull requests.
---
--- @since 3.17.0
---@class nio.lsp.types.DiagnosticWorkspaceClientCapabilities
---@field refreshSupport? boolean Whether the client implementation supports a refresh request sent from the server to the client.  Note that this event is global and will force the client to refresh all pulled diagnostics currently shown. It should be used with absolute care and is useful for situation where a server for example detects a project wide change that requires such a calculation.

--- Provider options for a [CodeActionRequest](#CodeActionRequest).
---@class nio.lsp.types.CodeActionOptions : nio.lsp.types.WorkDoneProgressOptions
---@field codeActionKinds? nio.lsp.types.CodeActionKind[] CodeActionKinds that this server may return.  The list of kinds may be generic, such as `CodeActionKind.Refactor`, or the server may list out every specific kind they provide.
---@field resolveProvider? boolean The server provides support to resolve additional information for a code action.  @since 3.16.0

---@class nio.lsp.types.TextDocumentSyncClientCapabilities
---@field dynamicRegistration? boolean Whether text document synchronization supports dynamic registration.
---@field willSave? boolean The client supports sending will save notifications.
---@field willSaveWaitUntil? boolean The client supports sending a will save request and waits for a response providing text edits which will be applied to the document before it is saved.
---@field didSave? boolean The client supports did save notifications.

---@class nio.lsp.types.Structure23
---@field properties string[] The properties that a client can resolve lazily.

--- @since 3.16.0
---@class nio.lsp.types.SemanticTokensLegend
---@field tokenTypes string[] The token types a server uses.
---@field tokenModifiers string[] The token modifiers a server uses.
---@alias nio.lsp.types.DefinitionLink nio.lsp.types.LocationLink

---@class nio.lsp.types.ImplementationParams : nio.lsp.types.TextDocumentPositionParams,nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams

---@class nio.lsp.types.Structure20
---@field text string The new text of the whole document.

--- Server capabilities for a [WorkspaceSymbolRequest](#WorkspaceSymbolRequest).
---@class nio.lsp.types.WorkspaceSymbolOptions : nio.lsp.types.WorkDoneProgressOptions
---@field resolveProvider? boolean The server provides support to resolve additional information for a workspace symbol.  @since 3.17.0

---@class nio.lsp.types.ImplementationRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.ImplementationOptions,nio.lsp.types.StaticRegistrationOptions

--- @since 3.14.0
---@class nio.lsp.types.DeclarationClientCapabilities
---@field dynamicRegistration? boolean Whether declaration supports dynamic registration. If this is set to `true` the client supports the new `DeclarationRegistrationOptions` return value for the corresponding server capability as well.
---@field linkSupport? boolean The client supports additional metadata in the form of declaration links.

---@class nio.lsp.types.TypeDefinitionParams : nio.lsp.types.TextDocumentPositionParams,nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams

---@class nio.lsp.types.TypeDefinitionRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.TypeDefinitionOptions,nio.lsp.types.StaticRegistrationOptions

--- A literal to identify a text document in the client.
---@class nio.lsp.types.TextDocumentIdentifier
---@field uri nio.lsp.types.DocumentUri The text document's uri.

--- A text document identifier to optionally denote a specific version of a text document.
---@class nio.lsp.types.OptionalVersionedTextDocumentIdentifier : nio.lsp.types.TextDocumentIdentifier
---@field version integer|nil The version number of this document. If a versioned text document identifier is sent from the server to the client and the file is not open in the editor (the server has not received an open notification before) the server can send `null` to indicate that the version is unknown and the content on disk is the truth (as specified with document content ownership).

--- Since 3.6.0
---@class nio.lsp.types.TypeDefinitionClientCapabilities
---@field dynamicRegistration? boolean Whether implementation supports dynamic registration. If this is set to `true` the client supports the new `TypeDefinitionRegistrationOptions` return value for the corresponding server capability as well.
---@field linkSupport? boolean The client supports additional metadata in the form of definition links.  Since 3.14.0

--- A special text edit with an additional change annotation.
---
--- @since 3.16.0.
---@class nio.lsp.types.AnnotatedTextEdit : nio.lsp.types.TextEdit
---@field annotationId nio.lsp.types.ChangeAnnotationIdentifier The actual identifier of the change annotation

--- @since 3.6.0
---@class nio.lsp.types.ImplementationClientCapabilities
---@field dynamicRegistration? boolean Whether implementation supports dynamic registration. If this is set to `true` the client supports the new `ImplementationRegistrationOptions` return value for the corresponding server capability as well.
---@field linkSupport? boolean The client supports additional metadata in the form of definition links.  @since 3.14.0

--- The parameters of a configuration request.
---@class nio.lsp.types.ConfigurationParams
---@field items nio.lsp.types.ConfigurationItem[]

---@class nio.lsp.types.DocumentColorOptions : nio.lsp.types.WorkDoneProgressOptions

--- Represents a color range from a document.
---@class nio.lsp.types.ColorInformation
---@field range nio.lsp.types.Range The range in the document where this color appears.
---@field color nio.lsp.types.Color The actual color value for this color range.

--- Options to create a file.
---@class nio.lsp.types.CreateFileOptions
---@field overwrite? boolean Overwrite existing file. Overwrite wins over `ignoreIfExists`
---@field ignoreIfExists? boolean Ignore if exists.

---@class nio.lsp.types.DocumentColorRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.DocumentColorOptions,nio.lsp.types.StaticRegistrationOptions

--- A generic resource operation.
---@class nio.lsp.types.ResourceOperation
---@field kind string The resource operation kind.
---@field annotationId? nio.lsp.types.ChangeAnnotationIdentifier An optional annotation identifier describing the operation.  @since 3.16.0

--- Provider options for a [DocumentLinkRequest](#DocumentLinkRequest).
---@class nio.lsp.types.DocumentLinkOptions : nio.lsp.types.WorkDoneProgressOptions
---@field resolveProvider? boolean Document links have a resolve provider as well.

---@class nio.lsp.types.ColorPresentation
---@field label string The label of this color presentation. It will be shown on the color picker header. By default this is also the text that is inserted when selecting this color presentation.
---@field textEdit? nio.lsp.types.TextEdit An [edit](#TextEdit) which is applied to a document when selecting this presentation for the color.  When `falsy` the [label](#ColorPresentation.label) is used.
---@field additionalTextEdits? nio.lsp.types.TextEdit[] An optional array of additional [text edits](#TextEdit) that are applied when selecting this color presentation. Edits must not overlap with the main [edit](#ColorPresentation.textEdit) nor with themselves.

--- Parameters for a [ColorPresentationRequest](#ColorPresentationRequest).
---@class nio.lsp.types.ColorPresentationParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The text document.
---@field color nio.lsp.types.Color The color to request presentations for.
---@field range nio.lsp.types.Range The range where the color would be inserted. Serves as a context.

--- Value-object describing what options formatting should use.
---@class nio.lsp.types.FormattingOptions
---@field tabSize integer Size of a tab in spaces.
---@field insertSpaces boolean Prefer spaces over tabs.
---@field trimTrailingWhitespace? boolean Trim trailing whitespace on a line.  @since 3.15.0
---@field insertFinalNewline? boolean Insert a newline character at the end of the file if one does not exist.  @since 3.15.0
---@field trimFinalNewlines? boolean Trim all newlines after the final newline at the end of the file.  @since 3.15.0

--- Rename file options
---@class nio.lsp.types.RenameFileOptions
---@field overwrite? boolean Overwrite target if existing. Overwrite wins over `ignoreIfExists`
---@field ignoreIfExists? boolean Ignores if target exists.

--- Provider options for a [DocumentFormattingRequest](#DocumentFormattingRequest).
---@class nio.lsp.types.DocumentFormattingOptions : nio.lsp.types.WorkDoneProgressOptions

--- Represents a folding range. To be valid, start and end line must be bigger than zero and smaller
--- than the number of lines in the document. Clients are free to ignore invalid ranges.
---@class nio.lsp.types.FoldingRange
---@field startLine integer The zero-based start line of the range to fold. The folded area starts after the line's last character. To be valid, the end must be zero or larger and smaller than the number of lines in the document.
---@field startCharacter? integer The zero-based character offset from where the folded range starts. If not defined, defaults to the length of the start line.
---@field endLine integer The zero-based end line of the range to fold. The folded area ends with the line's last character. To be valid, the end must be zero or larger and smaller than the number of lines in the document.
---@field endCharacter? integer The zero-based character offset before the folded range ends. If not defined, defaults to the length of the end line.
---@field kind? nio.lsp.types.FoldingRangeKind Describes the kind of the folding range such as `comment' or 'region'. The kind is used to categorize folding ranges and used by commands like 'Fold all comments'. See [FoldingRangeKind](#FoldingRangeKind) for an enumeration of standardized kinds.
---@field collapsedText? string The text that the client should show when the specified range is collapsed. If not defined or not supported by the client, a default will be chosen by the client.  @since 3.17.0

--- Parameters for a [FoldingRangeRequest](#FoldingRangeRequest).
---@class nio.lsp.types.FoldingRangeParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The text document.

--- Delete file options
---@class nio.lsp.types.DeleteFileOptions
---@field recursive? boolean Delete the content recursively if a folder is denoted.
---@field ignoreIfNotExists? boolean Ignore the operation if the file doesn't exist.

--- Provider options for a [DocumentRangeFormattingRequest](#DocumentRangeFormattingRequest).
---@class nio.lsp.types.DocumentRangeFormattingOptions : nio.lsp.types.WorkDoneProgressOptions
---@alias nio.lsp.types.DeclarationLink nio.lsp.types.LocationLink

---@class nio.lsp.types.DeclarationParams : nio.lsp.types.TextDocumentPositionParams,nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams

---@class nio.lsp.types.DeclarationRegistrationOptions : nio.lsp.types.DeclarationOptions,nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.StaticRegistrationOptions

--- A pattern to describe in which file operation requests or notifications
--- the server is interested in receiving.
---
--- @since 3.16.0
---@class nio.lsp.types.FileOperationPattern
---@field glob string The glob pattern to match. Glob patterns can have the following syntax: - `*` to match one or more characters in a path segment - `?` to match on one character in a path segment - `**` to match any number of path segments, including none - `{}` to group sub patterns into an OR expression. (e.g. `**​/*.{ts,js}` matches all TypeScript and JavaScript files) - `[]` to declare a range of characters to match in a path segment (e.g., `example.[0-9]` to match on `example.0`, `example.1`, …) - `[!...]` to negate a range of characters to match in a path segment (e.g., `example.[!0-9]` to match on `example.a`, `example.b`, but not `example.0`)
---@field matches? nio.lsp.types.FileOperationPatternKind Whether to match files or folders with this pattern.  Matches both if undefined.
---@field options? nio.lsp.types.FileOperationPatternOptions Additional options used during matching.

---@class nio.lsp.types.DeclarationOptions : nio.lsp.types.WorkDoneProgressOptions

---@class nio.lsp.types.SelectionRangeRegistrationOptions : nio.lsp.types.SelectionRangeOptions,nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.StaticRegistrationOptions

---@class nio.lsp.types.WorkDoneProgressCreateParams
---@field token nio.lsp.types.ProgressToken The token to be used to report progress.

--- Provider options for a [RenameRequest](#RenameRequest).
---@class nio.lsp.types.RenameOptions : nio.lsp.types.WorkDoneProgressOptions
---@field prepareProvider? boolean Renames should be checked and tested before being executed.  @since version 3.12.0

--- The parameter of a `textDocument/prepareCallHierarchy` request.
---
--- @since 3.16.0
---@class nio.lsp.types.CallHierarchyPrepareParams : nio.lsp.types.TextDocumentPositionParams,nio.lsp.types.WorkDoneProgressParams

---@class nio.lsp.types.SelectionRangeOptions : nio.lsp.types.WorkDoneProgressOptions

--- The server capabilities of a [ExecuteCommandRequest](#ExecuteCommandRequest).
---@class nio.lsp.types.ExecuteCommandOptions : nio.lsp.types.WorkDoneProgressOptions
---@field commands string[] The commands to be executed on the server

--- Represents an incoming call, e.g. a caller of a method or constructor.
---
--- @since 3.16.0
---@class nio.lsp.types.CallHierarchyIncomingCall
---@field from nio.lsp.types.CallHierarchyItem The item that makes the call.
---@field fromRanges nio.lsp.types.Range[] The ranges at which the calls appear. This is relative to the caller denoted by [`this.from`](#CallHierarchyIncomingCall.from).

--- Provide inline value as text.
---
--- @since 3.17.0
---@class nio.lsp.types.InlineValueText
---@field range nio.lsp.types.Range The document range for which the inline value applies.
---@field text string The text of the inline value.
--- Symbol tags are extra annotations that tweak the rendering of a symbol.
---
--- @since 3.16
---@alias nio.lsp.types.SymbolTag 1

--- Represents an outgoing call, e.g. calling a getter from a method or a method from a constructor etc.
---
--- @since 3.16.0
---@class nio.lsp.types.CallHierarchyOutgoingCall
---@field to nio.lsp.types.CallHierarchyItem The item that is called.
---@field fromRanges nio.lsp.types.Range[] The range at which this item is called. This is the range relative to the caller, e.g the item passed to [`provideCallHierarchyOutgoingCalls`](#CallHierarchyItemProvider.provideCallHierarchyOutgoingCalls) and not [`this.to`](#CallHierarchyOutgoingCall.to).

--- The parameter of a `callHierarchy/outgoingCalls` request.
---
--- @since 3.16.0
---@class nio.lsp.types.CallHierarchyOutgoingCallsParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field item nio.lsp.types.CallHierarchyItem

--- Provide inline value through a variable lookup.
--- If only a range is specified, the variable name will be extracted from the underlying document.
--- An optional variable name can be used to override the extracted name.
---
--- @since 3.17.0
---@class nio.lsp.types.InlineValueVariableLookup
---@field range nio.lsp.types.Range The document range for which the inline value applies. The range is used to extract the variable name from the underlying document.
---@field variableName? string If specified the name of the variable to look up.
---@field caseSensitiveLookup boolean How to perform the lookup.

--- @since 3.16.0
---@class nio.lsp.types.SemanticTokens
---@field resultId? string An optional result id. If provided and clients support delta updating the client will include the result id in the next semantic token request. A server can then instead of computing all semantic tokens again simply send a delta.
---@field data integer[] The actual tokens.

--- @since 3.16.0
---@class nio.lsp.types.SemanticTokensParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The text document.

--- @since 3.16.0
---@class nio.lsp.types.SemanticTokensPartialResult
---@field data integer[]

--- Call hierarchy options used during static registration.
---
--- @since 3.16.0
---@class nio.lsp.types.CallHierarchyOptions : nio.lsp.types.WorkDoneProgressOptions

--- @since 3.16.0
---@class nio.lsp.types.SemanticTokensRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.SemanticTokensOptions,nio.lsp.types.StaticRegistrationOptions

--- Provide an inline value through an expression evaluation.
--- If only a range is specified, the expression will be extracted from the underlying document.
--- An optional expression can be used to override the extracted expression.
---
--- @since 3.17.0
---@class nio.lsp.types.InlineValueEvaluatableExpression
---@field range nio.lsp.types.Range The document range for which the inline value applies. The range is used to extract the evaluatable expression from the underlying document.
---@field expression? string If specified the expression overrides the extracted expression.

--- @since 3.16.0
---@class nio.lsp.types.SemanticTokensDelta
---@field resultId? string
---@field edits nio.lsp.types.SemanticTokensEdit[] The semantic token edits to transform a previous result into a new result.

--- @since 3.16.0
---@class nio.lsp.types.SemanticTokensDeltaParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The text document.
---@field previousResultId string The result id of a previous response. The result Id can either point to a full response or a delta response depending on what was received last.

--- @since 3.16.0
---@class nio.lsp.types.SemanticTokensDeltaPartialResult
---@field edits nio.lsp.types.SemanticTokensEdit[]

--- @since 3.16.0
---@class nio.lsp.types.SemanticTokensRangeParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The text document.
---@field range nio.lsp.types.Range The range the semantic tokens are requested for.

--- The result of a showDocument request.
---
--- @since 3.16.0
---@class nio.lsp.types.ShowDocumentResult
---@field success boolean A boolean indicating if the show was successful.

--- Params to show a document.
---
--- @since 3.16.0
---@class nio.lsp.types.ShowDocumentParams
---@field uri nio.lsp.types.URI The document uri to show.
---@field external? boolean Indicates to show the resource in an external program. To show for example `https://code.visualstudio.com/` in the default WEB browser set `external` to `true`.
---@field takeFocus? boolean An optional property to indicate whether the editor showing the document should take focus or not. Clients might ignore this property if an external program is started.
---@field selection? nio.lsp.types.Range An optional selection range if the document is a text document. Clients might ignore the property if an external program is started or the file is not a text file.

--- @since 3.16.0
---@class nio.lsp.types.SemanticTokensOptions : nio.lsp.types.WorkDoneProgressOptions
---@field legend nio.lsp.types.SemanticTokensLegend The legend used by the server
---@field range? boolean|nio.lsp.types.Structure5 Server supports providing semantic tokens for a specific range of a document.
---@field full? boolean|nio.lsp.types.Structure6 Server supports providing semantic tokens for a full document.

---@class nio.lsp.types.LinkedEditingRangeParams : nio.lsp.types.TextDocumentPositionParams,nio.lsp.types.WorkDoneProgressParams

--- @since 3.16.0
---@class nio.lsp.types.SemanticTokensEdit
---@field start integer The start offset of the edit.
---@field deleteCount integer The count of elements to remove.
---@field data? integer[] The elements to insert.

--- A full diagnostic report with a set of related documents.
---
--- @since 3.17.0
---@class nio.lsp.types.RelatedFullDocumentDiagnosticReport : nio.lsp.types.FullDocumentDiagnosticReport
---@field relatedDocuments? table<nio.lsp.types.DocumentUri, nio.lsp.types.FullDocumentDiagnosticReport|nio.lsp.types.UnchangedDocumentDiagnosticReport> Diagnostics of related documents. This information is useful in programming languages where code in a file A can generate diagnostics in a file B which A depends on. An example of such a language is C/C++ where marco definitions in a file a.cpp and result in errors in a header file b.hpp.  @since 3.17.0

--- The parameters sent in notifications/requests for user-initiated creation of
--- files.
---
--- @since 3.16.0
---@class nio.lsp.types.CreateFilesParams
---@field files nio.lsp.types.FileCreate[] An array of all files/folders created in this operation.

--- The options to register for file operations.
---
--- @since 3.16.0
---@class nio.lsp.types.FileOperationRegistrationOptions
---@field filters nio.lsp.types.FileOperationFilter[] The actual filters.

--- An unchanged diagnostic report with a set of related documents.
---
--- @since 3.17.0
---@class nio.lsp.types.RelatedUnchangedDocumentDiagnosticReport : nio.lsp.types.UnchangedDocumentDiagnosticReport
---@field relatedDocuments? table<nio.lsp.types.DocumentUri, nio.lsp.types.FullDocumentDiagnosticReport|nio.lsp.types.UnchangedDocumentDiagnosticReport> Diagnostics of related documents. This information is useful in programming languages where code in a file A can generate diagnostics in a file B which A depends on. An example of such a language is C/C++ where marco definitions in a file a.cpp and result in errors in a header file b.hpp.  @since 3.17.0

--- The parameters sent in notifications/requests for user-initiated renames of
--- files.
---
--- @since 3.16.0
---@class nio.lsp.types.RenameFilesParams
---@field files nio.lsp.types.FileRename[] An array of all files/folders renamed in this operation. When a folder is renamed, only the folder will be included, and not its children.

--- The parameters sent in notifications/requests for user-initiated deletes of
--- files.
---
--- @since 3.16.0
---@class nio.lsp.types.DeleteFilesParams
---@field files nio.lsp.types.FileDelete[] An array of all files/folders deleted in this operation.

---@class nio.lsp.types.LinkedEditingRangeOptions : nio.lsp.types.WorkDoneProgressOptions

--- Represents information on a file/folder create.
---
--- @since 3.16.0
---@class nio.lsp.types.FileCreate
---@field uri string A file:// URI for the location of the file/folder being created.

---@class nio.lsp.types.MonikerRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.MonikerOptions

---@class nio.lsp.types.Structure44
---@field properties string[] The properties that a client can resolve lazily. Usually `location.range`

--- Describes textual changes on a text document. A TextDocumentEdit describes all changes
--- on a document version Si and after they are applied move the document to version Si+1.
--- So the creator of a TextDocumentEdit doesn't need to sort the array of edits or do any
--- kind of ordering. However the edits must be non overlapping.
---@class nio.lsp.types.TextDocumentEdit
---@field textDocument nio.lsp.types.OptionalVersionedTextDocumentIdentifier The text document to change.
---@field edits nio.lsp.types.TextEdit|nio.lsp.types.AnnotatedTextEdit[] The edits to be applied.  @since 3.16.0 - support for AnnotatedTextEdit. This is guarded using a client capability.

--- Create file operation.
---@class nio.lsp.types.CreateFile : nio.lsp.types.ResourceOperation
---@field kind 'create' A create
---@field uri nio.lsp.types.DocumentUri The resource to create.
---@field options? nio.lsp.types.CreateFileOptions Additional options

--- Rename file operation
---@class nio.lsp.types.RenameFile : nio.lsp.types.ResourceOperation
---@field kind 'rename' A rename
---@field oldUri nio.lsp.types.DocumentUri The old (existing) location.
---@field newUri nio.lsp.types.DocumentUri The new location.
---@field options? nio.lsp.types.RenameFileOptions Rename options.

--- Delete file operation
---@class nio.lsp.types.DeleteFile : nio.lsp.types.ResourceOperation
---@field kind 'delete' A delete
---@field uri nio.lsp.types.DocumentUri The file to delete.
---@field options? nio.lsp.types.DeleteFileOptions Delete options.

---@class nio.lsp.types.Structure43
---@field valueSet nio.lsp.types.SymbolTag[] The tags supported by the client.

--- The parameter of a `typeHierarchy/supertypes` request.
---
--- @since 3.17.0
---@class nio.lsp.types.TypeHierarchySupertypesParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field item nio.lsp.types.TypeHierarchyItem
---@alias nio.lsp.types.ChangeAnnotationIdentifier string

--- Additional information that describes document changes.
---
--- @since 3.16.0
---@class nio.lsp.types.ChangeAnnotation
---@field label string A human-readable string describing the actual change. The string is rendered prominent in the user interface.
---@field needsConfirmation? boolean A flag which indicates that user confirmation is needed before applying the change.
---@field description? string A human-readable string which is rendered less prominent in the user interface.

---@class nio.lsp.types.Structure42
---@field valueSet? nio.lsp.types.SymbolKind[] The symbol kind values the client supports. When this property exists the client also guarantees that it will handle values outside its set gracefully and falls back to a default value when unknown.  If this property is not present the client only supports the symbol kinds from `File` to `Array` as defined in the initial version of the protocol.

--- LSP object definition.
--- @since 3.17.0
---@class nio.lsp.types.LSPObject

---@class nio.lsp.types.Structure41
---@field groupsOnLabel? boolean Whether the client groups edits with equal labels into tree nodes, for instance all edits labelled with "Changes in Strings" would be a tree node.

--- A filter to describe in which file operation requests or notifications
--- the server is interested in receiving.
---
--- @since 3.16.0
---@class nio.lsp.types.FileOperationFilter
---@field scheme? string A Uri scheme like `file` or `untitled`.
---@field pattern nio.lsp.types.FileOperationPattern The actual file operation pattern.

--- A notebook cell.
---
--- A cell's document URI must be unique across ALL notebook
--- cells and can therefore be used to uniquely identify a
--- notebook cell or the cell's text document.
---
--- @since 3.17.0
---@class nio.lsp.types.NotebookCell
---@field kind nio.lsp.types.NotebookCellKind The cell's kind
---@field document nio.lsp.types.DocumentUri The URI of the cell's text document content.
---@field metadata? nio.lsp.types.LSPObject Additional metadata stored with the cell.  Note: should always be an object literal (e.g. LSPObject)
---@field executionSummary? nio.lsp.types.ExecutionSummary Additional execution summary information if supported by the client.

--- Additional details for a completion item label.
---
--- @since 3.17.0
---@class nio.lsp.types.CompletionItemLabelDetails
---@field detail? string An optional string which is rendered less prominently directly after {@link CompletionItem.label label}, without any spacing. Should be used for function signatures and type annotations.
---@field description? string An optional string which is rendered less prominently after {@link CompletionItem.detail}. Should be used for fully qualified names and file paths.

--- Represents information on a file/folder rename.
---
--- @since 3.16.0
---@class nio.lsp.types.FileRename
---@field oldUri string A file:// URI for the original location of the file/folder being renamed.
---@field newUri string A file:// URI for the new location of the file/folder being renamed.

--- Client Capabilities for a [DefinitionRequest](#DefinitionRequest).
---@class nio.lsp.types.DefinitionClientCapabilities
---@field dynamicRegistration? boolean Whether definition supports dynamic registration.
---@field linkSupport? boolean The client supports additional metadata in the form of definition links.  @since 3.14.0

---@class nio.lsp.types.Structure38
---@field notebookType? string The type of the enclosing notebook.
---@field scheme? string A Uri [scheme](#Uri.scheme), like `file` or `untitled`.
---@field pattern string A glob pattern.

--- Represents information on a file/folder delete.
---
--- @since 3.16.0
---@class nio.lsp.types.FileDelete
---@field uri string A file:// URI for the location of the file/folder being deleted.

---@class nio.lsp.types.Structure37
---@field notebookType? string The type of the enclosing notebook.
---@field scheme string A Uri [scheme](#Uri.scheme), like `file` or `untitled`.
---@field pattern? string A glob pattern.

--- Parameters for a [DocumentColorRequest](#DocumentColorRequest).
---@class nio.lsp.types.DocumentColorParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The text document.

--- Client capabilities of a [DocumentRangeFormattingRequest](#DocumentRangeFormattingRequest).
---@class nio.lsp.types.DocumentRangeFormattingClientCapabilities
---@field dynamicRegistration? boolean Whether range formatting supports dynamic registration.

--- A change describing how to move a `NotebookCell`
--- array from state S to S'.
---
--- @since 3.17.0
---@class nio.lsp.types.NotebookCellArrayChange
---@field start integer The start oftest of the cell that changed.
---@field deleteCount integer The deleted cells
---@field cells? nio.lsp.types.NotebookCell[] The new cells, if any

---@class nio.lsp.types.Structure33
---@field name string The name of the server as defined by the server.
---@field version? string The server's version as defined by the server.

--- Client capabilities specific to the used markdown parser.
---
--- @since 3.16.0
---@class nio.lsp.types.MarkdownClientCapabilities
---@field parser string The name of the parser.
---@field version? string The version of the parser.
---@field allowedTags? string[] A list of HTML tags that the client allows / supports in Markdown.  @since 3.17.0
---@alias nio.lsp.types.LSPArray nio.lsp.types.LSPAny[]

---@class nio.lsp.types.Structure30
---@field valueSet nio.lsp.types.InsertTextMode[]
--- The moniker kind.
---
--- @since 3.16.0
---@alias nio.lsp.types.MonikerKind "import"|"export"|"local"

---@class nio.lsp.types.Structure29
---@field properties string[] The properties that a client can resolve lazily.

---@class nio.lsp.types.Structure28
---@field valueSet nio.lsp.types.CompletionItemTag[] The tags supported by the client.

---@class nio.lsp.types.MonikerOptions : nio.lsp.types.WorkDoneProgressOptions

---@class nio.lsp.types.Structure27
---@field valueSet nio.lsp.types.SymbolTag[] The tags supported by the client.

---@class nio.lsp.types.Structure26
---@field valueSet? nio.lsp.types.SymbolKind[] The symbol kind values the client supports. When this property exists the client also guarantees that it will handle values outside its set gracefully and falls back to a default value when unknown.  If this property is not present the client only supports the symbol kinds from `File` to `Array` as defined in the initial version of the protocol.
---@alias nio.lsp.types.DocumentFilter nio.lsp.types.TextDocumentFilter|nio.lsp.types.NotebookCellTextDocumentFilter

---@class nio.lsp.types.Structure22
---@field defaultBehavior boolean

--- Type hierarchy options used during static registration.
---
--- @since 3.17.0
---@class nio.lsp.types.TypeHierarchyOptions : nio.lsp.types.WorkDoneProgressOptions

---@class nio.lsp.types.Structure24
---@field valueSet? nio.lsp.types.FoldingRangeKind[] The folding range kind values the client supports. When this property exists the client also guarantees that it will handle values outside its set gracefully and falls back to a default value when unknown.

---@class nio.lsp.types.Structure25
---@field collapsedText? boolean If set, the client signals that it supports setting collapsedText on folding ranges to display custom labels instead of the default text.  @since 3.17.0

---@class nio.lsp.types.Structure21
---@field range nio.lsp.types.Range
---@field placeholder string

---@class nio.lsp.types.Structure19
---@field range nio.lsp.types.Range The range of the document that changed.
---@field rangeLength? integer The optional length of the range that got replaced.  @deprecated use range instead.
---@field text string The new text for the provided range.

--- @since 3.17.0
---@class nio.lsp.types.InlineValueContext
---@field frameId integer The stack frame (as a DAP Id) where the execution has stopped.
---@field stoppedLocation nio.lsp.types.Range The document range where execution has stopped. Typically the end position of the range denotes the line where the inline values are shown.

---@class nio.lsp.types.Structure17
---@field language? string A language id, like `typescript`.
---@field scheme? string A Uri [scheme](#Uri.scheme), like `file` or `untitled`.
---@field pattern string A glob pattern, like `*.{ts,js}`.
--- Predefined error codes.
---@alias nio.lsp.types.ErrorCodes -32700|-32600|-32601|-32602|-32603|-32002|-32001

--- Inline value options used during static registration.
---
--- @since 3.17.0
---@class nio.lsp.types.InlineValueOptions : nio.lsp.types.WorkDoneProgressOptions

---@class nio.lsp.types.Structure16
---@field language? string A language id, like `typescript`.
---@field scheme string A Uri [scheme](#Uri.scheme), like `file` or `untitled`.
---@field pattern? string A glob pattern, like `*.{ts,js}`.

--- @since 3.16.0
---@class nio.lsp.types.SemanticTokensClientCapabilities
---@field dynamicRegistration? boolean Whether implementation supports dynamic registration. If this is set to `true` the client supports the new `(TextDocumentRegistrationOptions & StaticRegistrationOptions)` return value for the corresponding server capability as well.
---@field requests nio.lsp.types.Structure45 Which requests the client supports and might send to the server depending on the server's capability. Please note that clients might not show semantic tokens or degrade some of the user experience if a range or full request is advertised by the client but not provided by the server. If for example the client capability `requests.full` and `request.range` are both set to true but the server only provides a range provider the client might not render a minimap correctly or might even decide to not show any semantic tokens at all.
---@field tokenTypes string[] The token types that the client supports.
---@field tokenModifiers string[] The token modifiers that the client supports.
---@field formats nio.lsp.types.TokenFormat[] The token formats the clients supports.
---@field overlappingTokenSupport? boolean Whether the client supports tokens that can overlap each other.
---@field multilineTokenSupport? boolean Whether the client supports tokens that can span multiple lines.
---@field serverCancelSupport? boolean Whether the client allows the server to actively cancel a semantic token request, e.g. supports returning LSPErrorCodes.ServerCancelled. If a server does the client needs to retrigger the request.  @since 3.17.0
---@field augmentsSyntaxTokens? boolean Whether the client uses semantic tokens to augment existing syntax tokens. If set to `true` client side created syntax tokens and semantic tokens are both used for colorization. If set to `false` the client only uses the returned semantic tokens for colorization.  If the value is `undefined` then the client behavior is not specified.  @since 3.17.0

---@class nio.lsp.types.Structure13
---@field structure? nio.lsp.types.Structure46 Changes to the cell structure to add or remove cells.
---@field data? nio.lsp.types.NotebookCell[] Changes to notebook cells properties like its kind, execution summary or metadata.
---@field textContent? nio.lsp.types.Structure47[] Changes to the text content of notebook cells.

---@class nio.lsp.types.DidChangeWatchedFilesClientCapabilities
---@field dynamicRegistration? boolean Did change watched files notification supports dynamic registration. Please note that the current protocol doesn't support static configuration for file changes from the server side.
---@field relativePatternSupport? boolean Whether the client has support for {@link  RelativePattern relative pattern} or not.  @since 3.17.0

--- An inlay hint label part allows for interactive and composite labels
--- of inlay hints.
---
--- @since 3.17.0
---@class nio.lsp.types.InlayHintLabelPart
---@field value string The value of this label part.
---@field tooltip? string|nio.lsp.types.MarkupContent The tooltip text when you hover over this label part. Depending on the client capability `inlayHint.resolveSupport` clients might resolve this property late using the resolve request.
---@field location? nio.lsp.types.Location An optional source code location that represents this label part.  The editor will use this location for the hover and for code navigation features: This part will become a clickable link that resolves to the definition of the symbol at the given location (not necessarily the location itself), it shows the hover that shows at the given location, and it shows a context menu with further code navigation commands.  Depending on the client capability `inlayHint.resolveSupport` clients might resolve this property late using the resolve request.
---@field command? nio.lsp.types.Command An optional command for this label part.  Depending on the client capability `inlayHint.resolveSupport` clients might resolve this property late using the resolve request.

--- Client Capabilities for a [SignatureHelpRequest](#SignatureHelpRequest).
---@class nio.lsp.types.SignatureHelpClientCapabilities
---@field dynamicRegistration? boolean Whether signature help supports dynamic registration.
---@field signatureInformation? nio.lsp.types.Structure48 The client supports the following `SignatureInformation` specific properties.
---@field contextSupport? boolean The client supports to send additional context information for a `textDocument/signatureHelp` request. A client that opts into contextSupport will also support the `retriggerCharacters` on `SignatureHelpOptions`.  @since 3.15.0
--- Inlay hint kinds.
---
--- @since 3.17.0
---@alias nio.lsp.types.InlayHintKind 1|2

--- Defines the capabilities provided by the client.
---@class nio.lsp.types.ClientCapabilities
---@field workspace? nio.lsp.types.WorkspaceClientCapabilities Workspace specific client capabilities.
---@field textDocument? nio.lsp.types.TextDocumentClientCapabilities Text document specific client capabilities.
---@field notebookDocument? nio.lsp.types.NotebookDocumentClientCapabilities Capabilities specific to the notebook document support.  @since 3.17.0
---@field window? nio.lsp.types.WindowClientCapabilities Window specific client capabilities.
---@field general? nio.lsp.types.GeneralClientCapabilities General client capabilities.  @since 3.16.0
---@field experimental? nio.lsp.types.LSPAny Experimental client capabilities.

---@class nio.lsp.types.Structure9
---@field notebook? string|nio.lsp.types.NotebookDocumentFilter The notebook to be synced If a string value is provided it matches against the notebook type. '*' matches every notebook.
---@field cells nio.lsp.types.Structure49[] The cells of the matching notebook to be synced.

--- Client capabilities for the showDocument request.
---
--- @since 3.16.0
---@class nio.lsp.types.ShowDocumentClientCapabilities
---@field support boolean The client has support for the showDocument request.

--- A `MarkupContent` literal represents a string value which content is interpreted base on its
--- kind flag. Currently the protocol supports `plaintext` and `markdown` as markup kinds.
---
--- If the kind is `markdown` then the value can contain fenced code blocks like in GitHub issues.
--- See https://help.github.com/articles/creating-and-highlighting-code-blocks/#syntax-highlighting
---
--- Here is an example how such a string can be constructed using JavaScript / TypeScript:
--- ```ts
--- let markdown: MarkdownContent = {
---  kind: MarkupKind.Markdown,
---  value: [
---    '# Header',
---    'Some text',
---    '```typescript',
---    'someCode();',
---    '```'
---  ].join('\n')
--- };
--- ```
---
--- *Please Note* that clients might sanitize the return markdown. A client could decide to
--- remove HTML from the markdown to avoid script execution.
---@class nio.lsp.types.MarkupContent
---@field kind nio.lsp.types.MarkupKind The type of the Markup
---@field value string The content itself

---@class nio.lsp.types.Structure7
---@field valueSet nio.lsp.types.CodeActionKind[] The code action kind values the client supports. When this property exists the client also guarantees that it will handle values outside its set gracefully and falls back to a default value when unknown.

---@class nio.lsp.types.Structure6
---@field delta? boolean The server supports deltas for full documents.

---@class nio.lsp.types.Structure2
---@field properties string[] The properties that a client can resolve lazily.

---@class nio.lsp.types.Structure0
---@field workspaceFolders? nio.lsp.types.WorkspaceFoldersServerCapabilities The server supports workspace folder.  @since 3.6.0
---@field fileOperations? nio.lsp.types.FileOperationOptions The server is interested in notifications/requests for operations on files.  @since 3.16.0

---@class nio.lsp.types.TextDocumentSyncOptions
---@field openClose? boolean Open and close notifications are sent to the server. If omitted open close notification should not be sent.
---@field change? nio.lsp.types.TextDocumentSyncKind Change notifications are sent to the server. See TextDocumentSyncKind.None, TextDocumentSyncKind.Full and TextDocumentSyncKind.Incremental. If omitted it defaults to TextDocumentSyncKind.None.
---@field willSave? boolean If present will save notifications are sent to the server. If omitted the notification should not be sent.
---@field willSaveWaitUntil? boolean If present will save wait until requests are sent to the server. If omitted the request should not be sent.
---@field save? boolean|nio.lsp.types.SaveOptions If present save notifications are sent to the server. If omitted the notification should not be sent.

---@class nio.lsp.types.Structure1
---@field codeActionKind nio.lsp.types.Structure7 The code action kind is support with the following value set.
---@alias nio.lsp.types.FailureHandlingKind "abort"|"transactional"|"textOnlyTransactional"|"undo"

--- Options specific to a notebook plus its cells
--- to be synced to the server.
---
--- If a selector provides a notebook document
--- filter but no cell selector all cells of a
--- matching notebook document will be synced.
---
--- If a selector provides no notebook document
--- filter but only a cell selector all notebook
--- document that contain at least one matching
--- cell will be synced.
---
--- @since 3.17.0
---@class nio.lsp.types.NotebookDocumentSyncOptions
---@field notebookSelector nio.lsp.types.Structure8|nio.lsp.types.Structure9[] The notebooks to be synced
---@field save? boolean Whether save notification should be forwarded to the server. Will only be honored if mode === `notebook`.

--- Registration options specific to a notebook.
---
--- @since 3.17.0
---@class nio.lsp.types.NotebookDocumentSyncRegistrationOptions : nio.lsp.types.NotebookDocumentSyncOptions,nio.lsp.types.StaticRegistrationOptions

--- The result of a linked editing range request.
---
--- @since 3.16.0
---@class nio.lsp.types.LinkedEditingRanges
---@field ranges nio.lsp.types.Range[] A list of ranges that can be edited together. The ranges must have identical length and contain identical text content. The ranges cannot overlap.
---@field wordPattern? string An optional word pattern (regular expression) that describes valid contents for the given ranges. If no pattern is provided, the client configuration's word pattern will be used.
--- The reason why code actions were requested.
---
--- @since 3.17.0
---@alias nio.lsp.types.CodeActionTriggerKind 1|2

--- Completion client capabilities
---@class nio.lsp.types.CompletionClientCapabilities
---@field dynamicRegistration? boolean Whether completion supports dynamic registration.
---@field completionItem? nio.lsp.types.Structure10 The client supports the following `CompletionItem` specific capabilities.
---@field completionItemKind? nio.lsp.types.Structure11
---@field insertTextMode? nio.lsp.types.InsertTextMode Defines how the client handles whitespace and indentation when accepting a completion item that uses multi line text in either `insertText` or `textEdit`.  @since 3.17.0
---@field contextSupport? boolean The client supports to send additional context information for a `textDocument/completion` request.
---@field completionList? nio.lsp.types.Structure12 The client supports the following `CompletionList` specific capabilities.  @since 3.17.0

--- A workspace folder inside a client.
---@class nio.lsp.types.WorkspaceFolder
---@field uri nio.lsp.types.URI The associated URI for this workspace folder.
---@field name string The name of the workspace folder. Used to refer to this workspace folder in the user interface.

--- A diagnostic report with a full set of problems.
---
--- @since 3.17.0
---@class nio.lsp.types.FullDocumentDiagnosticReport
---@field kind 'full' A full document diagnostic report.
---@field resultId? string An optional result id. If provided it will be sent on the next diagnostic request for the same document.
---@field items nio.lsp.types.Diagnostic[] The actual items.

--- A diagnostic report indicating that the last returned
--- report is still accurate.
---
--- @since 3.17.0
---@class nio.lsp.types.UnchangedDocumentDiagnosticReport
---@field kind 'unchanged' A document diagnostic report indicating no changes to the last result. A server can only return `unchanged` if result ids are provided.
---@field resultId string A result id which will be sent on the next diagnostic request for the same document.

---@class nio.lsp.types.Structure49
---@field language string
--- A set of predefined code action kinds
---@alias nio.lsp.types.CodeActionKind ""|"quickfix"|"refactor"|"refactor.extract"|"refactor.inline"|"refactor.rewrite"|"source"|"source.organizeImports"|"source.fixAll"

--- The kind of a completion entry.
---@alias nio.lsp.types.CompletionItemKind 1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25

--- Diagnostic options.
---
--- @since 3.17.0
---@class nio.lsp.types.DiagnosticOptions : nio.lsp.types.WorkDoneProgressOptions
---@field identifier? string An optional identifier under which the diagnostics are managed by the client.
---@field interFileDependencies boolean Whether the language has inter file dependencies meaning that editing code in one file can result in a different diagnostic set in another file. Inter file dependencies are common for most programming languages and typically uncommon for linters.
---@field workspaceDiagnostics boolean The server provides support for workspace diagnostics as well.
--- The diagnostic tags.
---
--- @since 3.15.0
---@alias nio.lsp.types.DiagnosticTag 1|2

---@alias nio.lsp.types.WatchKind 1|2|4

--- The file event type
---@alias nio.lsp.types.FileChangeType 1|2|3

--- A previous result id in a workspace pull request.
---
--- @since 3.17.0
---@class nio.lsp.types.PreviousResultId
---@field uri nio.lsp.types.DocumentUri The URI for which the client knowns a result id.
---@field value string The value of the previous result id.
--- A set of predefined position encoding kinds.
---
--- @since 3.17.0
---@alias nio.lsp.types.PositionEncodingKind "utf-8"|"utf-16"|"utf-32"

---@alias nio.lsp.types.Definition nio.lsp.types.Location|nio.lsp.types.Location[]
---@alias nio.lsp.types.WorkspaceDocumentDiagnosticReport nio.lsp.types.WorkspaceFullDocumentDiagnosticReport|nio.lsp.types.WorkspaceUnchangedDocumentDiagnosticReport
--- A document highlight kind.
---@alias nio.lsp.types.DocumentHighlightKind 1|2|3

--- How whitespace and indentation is handled during completion
--- item insertion.
---
--- @since 3.16.0
---@alias nio.lsp.types.InsertTextMode 1|2

--- Defines whether the insert text in a completion item should be interpreted as
--- plain text or a snippet.
---@alias nio.lsp.types.InsertTextFormat 1|2

--- A notebook document.
---
--- @since 3.17.0
---@class nio.lsp.types.NotebookDocument
---@field uri nio.lsp.types.URI The notebook document's uri.
---@field notebookType string The type of the notebook.
---@field version integer The version number of this document (it will increase after each change, including undo/redo).
---@field metadata? nio.lsp.types.LSPObject Additional metadata stored with the notebook document.  Note: should always be an object literal (e.g. LSPObject)
---@field cells nio.lsp.types.NotebookCell[] The cells of a notebook.

--- Client capabilities specific to regular expressions.
---
--- @since 3.16.0
---@class nio.lsp.types.RegularExpressionsClientCapabilities
---@field engine string The engine's name.
---@field version? string The engine's version.
---@alias nio.lsp.types.DocumentSelector nio.lsp.types.DocumentFilter[]

--- An item to transfer a text document from the client to the
--- server.
---@class nio.lsp.types.TextDocumentItem
---@field uri nio.lsp.types.DocumentUri The text document's uri.
---@field languageId string The text document's language identifier.
---@field version integer The version number of this document (it will increase after each change, including undo/redo).
---@field text string The content of the opened text document.
--- The message type
---@alias nio.lsp.types.MessageType 1|2|3|4

--- Moniker uniqueness level to define scope of the moniker.
---
--- @since 3.16.0
---@alias nio.lsp.types.UniquenessLevel "document"|"project"|"group"|"scheme"|"global"

--- A versioned notebook document identifier.
---
--- @since 3.17.0
---@class nio.lsp.types.VersionedNotebookDocumentIdentifier
---@field version integer The version number of this notebook document.
---@field uri nio.lsp.types.URI The notebook document's uri.
--- A symbol kind.
---@alias nio.lsp.types.SymbolKind 1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26

--- A change event for a notebook document.
---
--- @since 3.17.0
---@class nio.lsp.types.NotebookDocumentChangeEvent
---@field metadata? nio.lsp.types.LSPObject The changed meta data if any.  Note: should always be an object literal (e.g. LSPObject)
---@field cells? nio.lsp.types.Structure13 Changes to cells
--- A set of predefined range kinds.
---@alias nio.lsp.types.FoldingRangeKind "comment"|"imports"|"region"

---@alias nio.lsp.types.LSPErrorCodes -32803|-32802|-32801|-32800

--- A literal to identify a notebook document in the client.
---
--- @since 3.17.0
---@class nio.lsp.types.NotebookDocumentIdentifier
---@field uri nio.lsp.types.URI The notebook document's uri.
--- The document diagnostic report kinds.
---
--- @since 3.17.0
---@alias nio.lsp.types.DocumentDiagnosticReportKind "full"|"unchanged"

--- A set of predefined token modifiers. This set is not fixed
--- an clients can specify additional token types via the
--- corresponding client capabilities.
---
--- @since 3.16.0
---@alias nio.lsp.types.SemanticTokenModifiers "declaration"|"definition"|"readonly"|"static"|"deprecated"|"abstract"|"async"|"modification"|"documentation"|"defaultLibrary"

--- A set of predefined token types. This set is not fixed
--- an clients can specify additional token types via the
--- corresponding client capabilities.
---
--- @since 3.16.0
---@alias nio.lsp.types.SemanticTokenTypes "namespace"|"type"|"class"|"enum"|"interface"|"struct"|"typeParameter"|"parameter"|"variable"|"property"|"enumMember"|"event"|"function"|"method"|"macro"|"keyword"|"modifier"|"comment"|"string"|"number"|"regexp"|"operator"|"decorator"

---@alias nio.lsp.types.Pattern string

---@class nio.lsp.types.FoldingRangeOptions : nio.lsp.types.WorkDoneProgressOptions

--- General parameters to to register for an notification or to register a provider.
---@class nio.lsp.types.Registration
---@field id string The id used to register the request. The id can be used to deregister the request again.
---@field method string The method / capability to register for.
---@field registerOptions? nio.lsp.types.LSPAny Options necessary for the registration.

--- General parameters to unregister a request or notification.
---@class nio.lsp.types.Unregistration
---@field id string The id used to unregister the request or notification. Usually an id provided during the register request.
---@field method string The method to unregister for.

--- The initialize parameters
---@class nio.lsp.types._InitializeParams : nio.lsp.types.WorkDoneProgressParams
---@field processId integer|nil The process Id of the parent process that started the server.  Is `null` if the process has not been started by another process. If the parent process is not alive then the server should exit.
---@field clientInfo? nio.lsp.types.Structure14 Information about the client  @since 3.15.0
---@field locale? string The locale the client is currently showing the user interface in. This must not necessarily be the locale of the operating system.  Uses IETF language tags as the value's syntax (See https://en.wikipedia.org/wiki/IETF_language_tag)  @since 3.16.0
---@field rootPath? string|nil The rootPath of the workspace. Is null if no folder is open.  @deprecated in favour of rootUri.
---@field rootUri nio.lsp.types.DocumentUri|nil The rootUri of the workspace. Is null if no folder is open. If both `rootPath` and `rootUri` are set `rootUri` wins.  @deprecated in favour of workspaceFolders.
---@field capabilities nio.lsp.types.ClientCapabilities The capabilities provided by the client (editor or tool)
---@field initializationOptions? nio.lsp.types.LSPAny User provided initialization options.
---@field trace? 'off'|'messages'|'compact'|'verbose' The initial trace setting. If omitted trace is disabled ('off').

---@class nio.lsp.types.WorkspaceFoldersServerCapabilities
---@field supported? boolean The server has support for workspace folders
---@field changeNotifications? string|boolean Whether the server wants to receive workspace folder change notifications.  If a string is provided the string is treated as an ID under which the notification is registered on the client side. The ID can be used to unregister for these events using the `client/unregisterCapability` request.
---@alias nio.lsp.types.TextDocumentFilter nio.lsp.types.Structure15|nio.lsp.types.Structure16|nio.lsp.types.Structure17

---@class nio.lsp.types.Structure8
---@field notebook string|nio.lsp.types.NotebookDocumentFilter The notebook to be synced If a string value is provided it matches against the notebook type. '*' matches every notebook.
---@field cells? nio.lsp.types.Structure18[] The cells of the matching notebook to be synced.

--- Options for notifications/requests for user operations on files.
---
--- @since 3.16.0
---@class nio.lsp.types.FileOperationOptions
---@field didCreate? nio.lsp.types.FileOperationRegistrationOptions The server is interested in receiving didCreateFiles notifications.
---@field willCreate? nio.lsp.types.FileOperationRegistrationOptions The server is interested in receiving willCreateFiles requests.
---@field didRename? nio.lsp.types.FileOperationRegistrationOptions The server is interested in receiving didRenameFiles notifications.
---@field willRename? nio.lsp.types.FileOperationRegistrationOptions The server is interested in receiving willRenameFiles requests.
---@field didDelete? nio.lsp.types.FileOperationRegistrationOptions The server is interested in receiving didDeleteFiles file notifications.
---@field willDelete? nio.lsp.types.FileOperationRegistrationOptions The server is interested in receiving willDeleteFiles file requests.
---@alias nio.lsp.types.TextDocumentContentChangeEvent nio.lsp.types.Structure19|nio.lsp.types.Structure20
--- Defines how the host (editor) should sync
--- document changes to the language server.
---@alias nio.lsp.types.TextDocumentSyncKind 0|1|2

---@alias nio.lsp.types.ProgressToken integer|string
---@alias nio.lsp.types.PrepareRenameResult nio.lsp.types.Range|nio.lsp.types.Structure21|nio.lsp.types.Structure22

---@class nio.lsp.types.WorkDoneProgressBegin
---@field kind 'begin'
---@field title string Mandatory title of the progress operation. Used to briefly inform about the kind of operation being performed.  Examples: "Indexing" or "Linking dependencies".
---@field cancellable? boolean Controls if a cancel button should show to allow the user to cancel the long running operation. Clients that don't support cancellation are allowed to ignore the setting.
---@field message? string Optional, more detailed associated progress message. Contains complementary information to the `title`.  Examples: "3/25 files", "project/src/module2", "node_modules/some_dep". If unset, the previous progress message (if any) is still valid.
---@field percentage? integer Optional progress percentage to display (value 100 is considered 100%). If not provided infinite progress is assumed and clients are allowed to ignore the `percentage` value in subsequent in report notifications.  The value should be steadily rising. Clients are free to ignore values that are not following this rule. The value range is [0, 100].

--- Client Capabilities for a [ReferencesRequest](#ReferencesRequest).
---@class nio.lsp.types.ReferenceClientCapabilities
---@field dynamicRegistration? boolean Whether references supports dynamic registration.
---@alias nio.lsp.types.Declaration nio.lsp.types.Location|nio.lsp.types.Location[]
---@alias nio.lsp.types.LSPAny nio.lsp.types.LSPObject|nio.lsp.types.LSPArray|string|integer|integer|number|boolean|nil
--- Describes the content type that a client supports in various
--- result literals like `Hover`, `ParameterInfo` or `CompletionItem`.
---
--- Please note that `MarkupKinds` must not start with a `$`. This kinds
--- are reserved for internal usage.
---@alias nio.lsp.types.MarkupKind "plaintext"|"markdown"

---@class nio.lsp.types.Structure31
---@field cancel boolean The client will actively cancel the request.
---@field retryOnContentModified string[] The list of requests for which the client will retry the request if it receives a response with error code `ContentModified`
--- Represents reasons why a text document is saved.
---@alias nio.lsp.types.TextDocumentSaveReason 1|2|3

---@alias nio.lsp.types.GlobPattern nio.lsp.types.Pattern|nio.lsp.types.RelativePattern

--- An event describing a file change.
---@class nio.lsp.types.FileEvent
---@field uri nio.lsp.types.DocumentUri The file's uri.
---@field type nio.lsp.types.FileChangeType The change type.

--- Notebook specific client capabilities.
---
--- @since 3.17.0
---@class nio.lsp.types.NotebookDocumentSyncClientCapabilities
---@field dynamicRegistration? boolean Whether implementation supports dynamic registration. If this is set to `true` the client supports the new `(TextDocumentRegistrationOptions & StaticRegistrationOptions)` return value for the corresponding server capability as well.
---@field executionSummarySupport? boolean The client supports sending execution summary data per cell.

---@class nio.lsp.types.MonikerParams : nio.lsp.types.TextDocumentPositionParams,nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams

--- Inlay hint client capabilities.
---
--- @since 3.17.0
---@class nio.lsp.types.InlayHintClientCapabilities
---@field dynamicRegistration? boolean Whether inlay hints support dynamic registration.
---@field resolveSupport? nio.lsp.types.Structure23 Indicates which properties a client can resolve lazily on an inlay hint.

--- Client capabilities specific to inline values.
---
--- @since 3.17.0
---@class nio.lsp.types.InlineValueClientCapabilities
---@field dynamicRegistration? boolean Whether implementation supports dynamic registration for inline value providers.

--- @since 3.17.0
---@class nio.lsp.types.TypeHierarchyClientCapabilities
---@field dynamicRegistration? boolean Whether implementation supports dynamic registration. If this is set to `true` the client supports the new `(TextDocumentRegistrationOptions & StaticRegistrationOptions)` return value for the corresponding server capability as well.

--- Structure to capture a description for an error code.
---
--- @since 3.16.0
---@class nio.lsp.types.CodeDescription
---@field href nio.lsp.types.URI An URI to open with more information about the diagnostic error.

--- Client capabilities specific to the moniker request.
---
--- @since 3.16.0
---@class nio.lsp.types.MonikerClientCapabilities
---@field dynamicRegistration? boolean Whether moniker supports dynamic registration. If this is set to `true` the client supports the new `MonikerRegistrationOptions` return value for the corresponding server capability as well.

--- Represents a parameter of a callable-signature. A parameter can
--- have a label and a doc-comment.
---@class nio.lsp.types.ParameterInformation
---@field label string|integer,integer The label of this parameter information.  Either a string or an inclusive start and exclusive end offsets within its containing signature label. (see SignatureInformation.label). The offsets are based on a UTF-16 string representation as `Position` and `Range` does.  *Note*: a label of type string should be a substring of its containing signature label. Its intended use case is to highlight the parameter label part in the `SignatureInformation.label`.
---@field documentation? string|nio.lsp.types.MarkupContent The human-readable doc-comment of this parameter. Will be shown in the UI but can be omitted.

---@class nio.lsp.types.Structure14
---@field name string The name of the client as defined by the client.
---@field version? string The client's version as defined by the client.

--- A notebook cell text document filter denotes a cell text
--- document by different properties.
---
--- @since 3.17.0
---@class nio.lsp.types.NotebookCellTextDocumentFilter
---@field notebook string|nio.lsp.types.NotebookDocumentFilter A filter that matches against the notebook containing the notebook cell. If a string value is provided it matches against the notebook type. '*' matches every notebook.
---@field language? string A language id like `python`.  Will be matched against the language id of the notebook cell document. '*' matches every language.

--- Represents a related message and source code location for a diagnostic. This should be
--- used to point to code locations that cause or related to a diagnostics, e.g when duplicating
--- a symbol in a scope.
---@class nio.lsp.types.DiagnosticRelatedInformation
---@field location nio.lsp.types.Location The location of this related diagnostic information.
---@field message string The message of this related diagnostic information.

--- Matching options for the file operation pattern.
---
--- @since 3.16.0
---@class nio.lsp.types.FileOperationPatternOptions
---@field ignoreCase? boolean The pattern should be matched ignoring casing.

--- Capabilities specific to the notebook document support.
---
--- @since 3.17.0
---@class nio.lsp.types.NotebookDocumentClientCapabilities
---@field synchronization nio.lsp.types.NotebookDocumentSyncClientCapabilities Capabilities specific to notebook document synchronization  @since 3.17.0

---@class nio.lsp.types.FoldingRangeClientCapabilities
---@field dynamicRegistration? boolean Whether implementation supports dynamic registration for folding range providers. If this is set to `true` the client supports the new `FoldingRangeRegistrationOptions` return value for the corresponding server capability as well.
---@field rangeLimit? integer The maximum number of folding ranges that the client prefers to receive per document. The value serves as a hint, servers are free to follow the limit.
---@field lineFoldingOnly? boolean If set, the client signals that it only supports folding complete lines. If set, client will ignore specified `startCharacter` and `endCharacter` properties in a FoldingRange.
---@field foldingRangeKind? nio.lsp.types.Structure24 Specific options for the folding range kind.  @since 3.17.0
---@field foldingRange? nio.lsp.types.Structure25 Specific options for the folding range.  @since 3.17.0

--- A relative pattern is a helper to construct glob patterns that are matched
--- relatively to a base URI. The common value for a `baseUri` is a workspace
--- folder root, but it can be another absolute URI as well.
---
--- @since 3.17.0
---@class nio.lsp.types.RelativePattern
---@field baseUri nio.lsp.types.WorkspaceFolder|nio.lsp.types.URI A workspace folder or a base URI to which this pattern will be matched against relatively.
---@field pattern nio.lsp.types.Pattern The actual glob pattern;

--- Represents a reference to a command. Provides a title which
--- will be used to represent a command in the UI and, optionally,
--- an array of arguments which will be passed to the command handler
--- function when invoked.
---@class nio.lsp.types.Command
---@field title string Title of the command, like `save`.
---@field command string The identifier of the actual command handler.
---@field arguments? nio.lsp.types.LSPAny[] Arguments that the command handler should be invoked with.

--- Client capabilities of a [DocumentOnTypeFormattingRequest](#DocumentOnTypeFormattingRequest).
---@class nio.lsp.types.DocumentOnTypeFormattingClientCapabilities
---@field dynamicRegistration? boolean Whether on type formatting supports dynamic registration.

---@class nio.lsp.types.Structure34
---@field commitCharacters? string[] A default commit character set.  @since 3.17.0
---@field editRange? nio.lsp.types.Range|nio.lsp.types.Structure50 A default edit range.  @since 3.17.0
---@field insertTextFormat? nio.lsp.types.InsertTextFormat A default insert text format.  @since 3.17.0
---@field insertTextMode? nio.lsp.types.InsertTextMode A default insert text mode.  @since 3.17.0
---@field data? nio.lsp.types.LSPAny A default data value.  @since 3.17.0

---@class nio.lsp.types.Structure40
---@field reason string Human readable description of why the code action is currently disabled.  This is displayed in the code actions UI.

---@class nio.lsp.types.DocumentColorClientCapabilities
---@field dynamicRegistration? boolean Whether implementation supports dynamic registration. If this is set to `true` the client supports the new `DocumentColorRegistrationOptions` return value for the corresponding server capability as well.

--- The client capabilities of a [DocumentLinkRequest](#DocumentLinkRequest).
---@class nio.lsp.types.DocumentLinkClientCapabilities
---@field dynamicRegistration? boolean Whether document link supports dynamic registration.
---@field tooltipSupport? boolean Whether the client supports the `tooltip` property on `DocumentLink`.  @since 3.15.0

--- The parameter of a `typeHierarchy/subtypes` request.
---
--- @since 3.17.0
---@class nio.lsp.types.TypeHierarchySubtypesParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field item nio.lsp.types.TypeHierarchyItem

--- The client capabilities  of a [CodeLensRequest](#CodeLensRequest).
---@class nio.lsp.types.CodeLensClientCapabilities
---@field dynamicRegistration? boolean Whether code lens supports dynamic registration.

--- Client Capabilities for a [DocumentSymbolRequest](#DocumentSymbolRequest).
---@class nio.lsp.types.DocumentSymbolClientCapabilities
---@field dynamicRegistration? boolean Whether document symbol supports dynamic registration.
---@field symbolKind? nio.lsp.types.Structure26 Specific capabilities for the `SymbolKind` in the `textDocument/documentSymbol` request.
---@field hierarchicalDocumentSymbolSupport? boolean The client supports hierarchical document symbols.
---@field tagSupport? nio.lsp.types.Structure27 The client supports tags on `SymbolInformation`. Tags are supported on `DocumentSymbol` if `hierarchicalDocumentSymbolSupport` is set to true. Clients supporting tags have to handle unknown tags gracefully.  @since 3.16.0
---@field labelSupport? boolean The client supports an additional label presented in the UI when registering a document symbol provider.  @since 3.16.0
---@alias nio.lsp.types.InlineValue nio.lsp.types.InlineValueText|nio.lsp.types.InlineValueVariableLookup|nio.lsp.types.InlineValueEvaluatableExpression

--- A parameter literal used in inline value requests.
---
--- @since 3.17.0
---@class nio.lsp.types.InlineValueParams : nio.lsp.types.WorkDoneProgressParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The text document.
---@field range nio.lsp.types.Range The document range for which inline values should be computed.
---@field context nio.lsp.types.InlineValueContext Additional information about the context in which inline values were requested.

--- Inline value options used during static or dynamic registration.
---
--- @since 3.17.0
---@class nio.lsp.types.InlineValueRegistrationOptions : nio.lsp.types.InlineValueOptions,nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.StaticRegistrationOptions

---@class nio.lsp.types.Structure39
---@field uri nio.lsp.types.DocumentUri

---@class nio.lsp.types.Structure10
---@field snippetSupport? boolean Client supports snippets as insert text.  A snippet can define tab stops and placeholders with `$1`, `$2` and `${3:foo}`. `$0` defines the final tab stop, it defaults to the end of the snippet. Placeholders with equal identifiers are linked, that is typing in one will update others too.
---@field commitCharactersSupport? boolean Client supports commit characters on a completion item.
---@field documentationFormat? nio.lsp.types.MarkupKind[] Client supports the following content formats for the documentation property. The order describes the preferred format of the client.
---@field deprecatedSupport? boolean Client supports the deprecated property on a completion item.
---@field preselectSupport? boolean Client supports the preselect property on a completion item.
---@field tagSupport? nio.lsp.types.Structure28 Client supports the tag property on a completion item. Clients supporting tags have to handle unknown tags gracefully. Clients especially need to preserve unknown tags when sending a completion item back to the server in a resolve call.  @since 3.15.0
---@field insertReplaceSupport? boolean Client support insert replace edit to control different behavior if a completion item is inserted in the text or should replace text.  @since 3.16.0
---@field resolveSupport? nio.lsp.types.Structure29 Indicates which properties a client can resolve lazily on a completion item. Before version 3.16.0 only the predefined properties `documentation` and `details` could be resolved lazily.  @since 3.16.0
---@field insertTextModeSupport? nio.lsp.types.Structure30 The client supports the `insertTextMode` property on a completion item to override the whitespace handling mode as defined by the client (see `insertTextMode`).  @since 3.16.0
---@field labelDetailsSupport? boolean The client has support for completion item label details (see also `CompletionItemLabelDetails`).  @since 3.17.0

---@class nio.lsp.types.HoverClientCapabilities
---@field dynamicRegistration? boolean Whether hover supports dynamic registration.
---@field contentFormat? nio.lsp.types.MarkupKind[] Client supports the following content formats for the content property. The order describes the preferred format of the client.

--- Inlay hint information.
---
--- @since 3.17.0
---@class nio.lsp.types.InlayHint
---@field position nio.lsp.types.Position The position of this hint.
---@field label string|nio.lsp.types.InlayHintLabelPart[] The label of this hint. A human readable string or an array of InlayHintLabelPart label parts.  *Note* that neither the string nor the label part can be empty.
---@field kind? nio.lsp.types.InlayHintKind The kind of this hint. Can be omitted in which case the client should fall back to a reasonable default.
---@field textEdits? nio.lsp.types.TextEdit[] Optional text edits that are performed when accepting this inlay hint.  *Note* that edits are expected to change the document so that the inlay hint (or its nearest variant) is now part of the document and the inlay hint itself is now obsolete.
---@field tooltip? string|nio.lsp.types.MarkupContent The tooltip text when you hover over this item.
---@field paddingLeft? boolean Render padding before the hint.  Note: Padding should use the editor's background color, not the background color of the hint itself. That means padding can be used to visually align/separate an inlay hint.
---@field paddingRight? boolean Render padding after the hint.  Note: Padding should use the editor's background color, not the background color of the hint itself. That means padding can be used to visually align/separate an inlay hint.
---@field data? nio.lsp.types.LSPAny A data entry field that is preserved on an inlay hint between a `textDocument/inlayHint` and a `inlayHint/resolve` request.

--- A parameter literal used in inlay hint requests.
---
--- @since 3.17.0
---@class nio.lsp.types.InlayHintParams : nio.lsp.types.WorkDoneProgressParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The text document.
---@field range nio.lsp.types.Range The document range for which inlay hints should be computed.

--- Inlay hint options used during static or dynamic registration.
---
--- @since 3.17.0
---@class nio.lsp.types.InlayHintRegistrationOptions : nio.lsp.types.InlayHintOptions,nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.StaticRegistrationOptions
--- How a signature help was triggered.
---
--- @since 3.15.0
---@alias nio.lsp.types.SignatureHelpTriggerKind 1|2|3

---@class nio.lsp.types.WorkDoneProgressOptions
---@field workDoneProgress? boolean

--- Client capabilities of a [DocumentFormattingRequest](#DocumentFormattingRequest).
---@class nio.lsp.types.DocumentFormattingClientCapabilities
---@field dynamicRegistration? boolean Whether formatting supports dynamic registration.

---@class nio.lsp.types.Structure11
---@field valueSet? nio.lsp.types.CompletionItemKind[] The completion item kind values the client supports. When this property exists the client also guarantees that it will handle values outside its set gracefully and falls back to a default value when unknown.  If this property is not present the client only supports the completion items kinds from `Text` to `Reference` as defined in the initial version of the protocol.
---@alias nio.lsp.types.DocumentDiagnosticReport nio.lsp.types.RelatedFullDocumentDiagnosticReport|nio.lsp.types.RelatedUnchangedDocumentDiagnosticReport

--- Parameters of the document diagnostic request.
---
--- @since 3.17.0
---@class nio.lsp.types.DocumentDiagnosticParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The text document.
---@field identifier? string The additional identifier  provided during registration.
---@field previousResultId? string The result id of a previous response if provided.

--- A partial result for a document diagnostic report.
---
--- @since 3.17.0
---@class nio.lsp.types.DocumentDiagnosticReportPartialResult
---@field relatedDocuments table<nio.lsp.types.DocumentUri, nio.lsp.types.FullDocumentDiagnosticReport|nio.lsp.types.UnchangedDocumentDiagnosticReport>

--- Code Lens provider options of a [CodeLensRequest](#CodeLensRequest).
---@class nio.lsp.types.CodeLensOptions : nio.lsp.types.WorkDoneProgressOptions
---@field resolveProvider? boolean Code lens has a resolve provider as well.

--- Cancellation data returned from a diagnostic request.
---
--- @since 3.17.0
---@class nio.lsp.types.DiagnosticServerCancellationData
---@field retriggerRequest boolean

--- Diagnostic registration options.
---
--- @since 3.17.0
---@class nio.lsp.types.DiagnosticRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.DiagnosticOptions,nio.lsp.types.StaticRegistrationOptions

---@class nio.lsp.types.RenameClientCapabilities
---@field dynamicRegistration? boolean Whether rename supports dynamic registration.
---@field prepareSupport? boolean Client supports testing for validity of rename operations before execution.  @since 3.12.0
---@field prepareSupportDefaultBehavior? nio.lsp.types.PrepareSupportDefaultBehavior Client supports the default behavior result.  The value indicates the default behavior used by the client.  @since 3.16.0
---@field honorsChangeAnnotations? boolean Whether the client honors the change annotations in text edits and resource operations returned via the rename request's workspace edit by for example presenting the workspace edit in the user interface and asking for confirmation.  @since 3.16.0

--- General client capabilities.
---
--- @since 3.16.0
---@class nio.lsp.types.GeneralClientCapabilities
---@field staleRequestSupport? nio.lsp.types.Structure31 Client capability that signals how the client handles stale requests (e.g. a request for which the client will not process the response anymore since the information is outdated).  @since 3.17.0
---@field regularExpressions? nio.lsp.types.RegularExpressionsClientCapabilities Client capabilities specific to regular expressions.  @since 3.16.0
---@field markdown? nio.lsp.types.MarkdownClientCapabilities Client capabilities specific to the client's markdown parser.  @since 3.16.0
---@field positionEncodings? nio.lsp.types.PositionEncodingKind[] The position encodings supported by the client. Client and server have to agree on the same position encoding to ensure that offsets (e.g. character position in a line) are interpreted the same on both sides.  To keep the protocol backwards compatible the following applies: if the value 'utf-16' is missing from the array of position encodings servers can assume that the client supports UTF-16. UTF-16 is therefore a mandatory encoding.  If omitted it defaults to ['utf-16'].  Implementation considerations: since the conversion from one encoding into another requires the content of the file / line the conversion is best done where the file is read which is usually on the server side.  @since 3.17.0

--- A workspace diagnostic report.
---
--- @since 3.17.0
---@class nio.lsp.types.WorkspaceDiagnosticReport
---@field items nio.lsp.types.WorkspaceDocumentDiagnosticReport[]

--- Parameters of the workspace diagnostic request.
---
--- @since 3.17.0
---@class nio.lsp.types.WorkspaceDiagnosticParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field identifier? string The additional identifier provided during registration.
---@field previousResultIds nio.lsp.types.PreviousResultId[] The currently known diagnostic reports with their previous result ids.

--- A partial result for a workspace diagnostic report.
---
--- @since 3.17.0
---@class nio.lsp.types.WorkspaceDiagnosticReportPartialResult
---@field items nio.lsp.types.WorkspaceDocumentDiagnosticReport[]

---@class nio.lsp.types.SelectionRangeClientCapabilities
---@field dynamicRegistration? boolean Whether implementation supports dynamic registration for selection range providers. If this is set to `true` the client supports the new `SelectionRangeRegistrationOptions` return value for the corresponding server capability as well.

--- Workspace specific client capabilities.
---@class nio.lsp.types.WorkspaceClientCapabilities
---@field applyEdit? boolean The client supports applying batch edits to the workspace by supporting the request 'workspace/applyEdit'
---@field workspaceEdit? nio.lsp.types.WorkspaceEditClientCapabilities Capabilities specific to `WorkspaceEdit`s.
---@field didChangeConfiguration? nio.lsp.types.DidChangeConfigurationClientCapabilities Capabilities specific to the `workspace/didChangeConfiguration` notification.
---@field didChangeWatchedFiles? nio.lsp.types.DidChangeWatchedFilesClientCapabilities Capabilities specific to the `workspace/didChangeWatchedFiles` notification.
---@field symbol? nio.lsp.types.WorkspaceSymbolClientCapabilities Capabilities specific to the `workspace/symbol` request.
---@field executeCommand? nio.lsp.types.ExecuteCommandClientCapabilities Capabilities specific to the `workspace/executeCommand` request.
---@field workspaceFolders? boolean The client has support for workspace folders.  @since 3.6.0
---@field configuration? boolean The client supports `workspace/configuration` requests.  @since 3.6.0
---@field semanticTokens? nio.lsp.types.SemanticTokensWorkspaceClientCapabilities Capabilities specific to the semantic token requests scoped to the workspace.  @since 3.16.0.
---@field codeLens? nio.lsp.types.CodeLensWorkspaceClientCapabilities Capabilities specific to the code lens requests scoped to the workspace.  @since 3.16.0.
---@field fileOperations? nio.lsp.types.FileOperationClientCapabilities The client has support for file notifications/requests for user operations on files.  Since 3.16.0
---@field inlineValue? nio.lsp.types.InlineValueWorkspaceClientCapabilities Capabilities specific to the inline values requests scoped to the workspace.  @since 3.17.0.
---@field inlayHint? nio.lsp.types.InlayHintWorkspaceClientCapabilities Capabilities specific to the inlay hint requests scoped to the workspace.  @since 3.17.0.
---@field diagnostics? nio.lsp.types.DiagnosticWorkspaceClientCapabilities Capabilities specific to the diagnostic requests scoped to the workspace.  @since 3.17.0.

--- The publish diagnostic client capabilities.
---@class nio.lsp.types.PublishDiagnosticsClientCapabilities
---@field relatedInformation? boolean Whether the clients accepts diagnostics with related information.
---@field tagSupport? nio.lsp.types.Structure32 Client supports the tag property to provide meta data about a diagnostic. Clients supporting tags have to handle unknown tags gracefully.  @since 3.15.0
---@field versionSupport? boolean Whether the client interprets the version property of the `textDocument/publishDiagnostics` notification's parameter.  @since 3.15.0
---@field codeDescriptionSupport? boolean Client supports a codeDescription property  @since 3.16.0
---@field dataSupport? boolean Whether code action supports the `data` property which is preserved between a `textDocument/publishDiagnostics` and `textDocument/codeAction` request.  @since 3.16.0

---@class nio.lsp.types.RegistrationParams
---@field registrations nio.lsp.types.Registration[]

--- @since 3.16.0
---@class nio.lsp.types.CallHierarchyClientCapabilities
---@field dynamicRegistration? boolean Whether implementation supports dynamic registration. If this is set to `true` the client supports the new `(TextDocumentRegistrationOptions & StaticRegistrationOptions)` return value for the corresponding server capability as well.

---@class nio.lsp.types.UnregistrationParams
---@field unregisterations nio.lsp.types.Unregistration[]

--- Represents a location inside a resource, such as a line
--- inside a text file.
---@class nio.lsp.types.Location
---@field uri nio.lsp.types.DocumentUri
---@field range nio.lsp.types.Range

--- The result returned from an initialize request.
---@class nio.lsp.types.InitializeResult
---@field capabilities nio.lsp.types.ServerCapabilities The capabilities the language server provides.
---@field serverInfo? nio.lsp.types.Structure33 Information about the server.  @since 3.15.0

---@class nio.lsp.types.InitializeParams : nio.lsp.types._InitializeParams,nio.lsp.types.WorkspaceFoldersInitializeParams

--- Client capabilities for the linked editing range request.
---
--- @since 3.16.0
---@class nio.lsp.types.LinkedEditingRangeClientCapabilities
---@field dynamicRegistration? boolean Whether implementation supports dynamic registration. If this is set to `true` the client supports the new `(TextDocumentRegistrationOptions & StaticRegistrationOptions)` return value for the corresponding server capability as well.

--- Type hierarchy options used during static or dynamic registration.
---
--- @since 3.17.0
---@class nio.lsp.types.TypeHierarchyRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.TypeHierarchyOptions,nio.lsp.types.StaticRegistrationOptions

---@class nio.lsp.types.MessageActionItem
---@field title string A short title like 'Retry', 'Open Log' etc.

---@class nio.lsp.types.ShowMessageRequestParams
---@field type nio.lsp.types.MessageType The message type. See {@link MessageType}
---@field message string The actual message.
---@field actions? nio.lsp.types.MessageActionItem[] The message action items to present.

--- The parameter of a `textDocument/prepareTypeHierarchy` request.
---
--- @since 3.17.0
---@class nio.lsp.types.TypeHierarchyPrepareParams : nio.lsp.types.TextDocumentPositionParams,nio.lsp.types.WorkDoneProgressParams

--- A text edit applicable to a text document.
---@class nio.lsp.types.TextEdit
---@field range nio.lsp.types.Range The range of the text document to be manipulated. To insert text into a document create a range where start === end.
---@field newText string The string to be inserted. For delete operations use an empty string.

--- The parameters sent in a will save text document notification.
---@class nio.lsp.types.WillSaveTextDocumentParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The document that will be saved.
---@field reason nio.lsp.types.TextDocumentSaveReason The 'TextDocumentSaveReason'.

--- @since 3.17.0
---@class nio.lsp.types.TypeHierarchyItem
---@field name string The name of this item.
---@field kind nio.lsp.types.SymbolKind The kind of this item.
---@field tags? nio.lsp.types.SymbolTag[] Tags for this item.
---@field detail? string More detail for this item, e.g. the signature of a function.
---@field uri nio.lsp.types.DocumentUri The resource identifier of this item.
---@field range nio.lsp.types.Range The range enclosing this symbol not including leading/trailing whitespace but everything else, e.g. comments and code.
---@field selectionRange nio.lsp.types.Range The range that should be selected and revealed when this symbol is being picked, e.g. the name of a function. Must be contained by the [`range`](#TypeHierarchyItem.range).
---@field data? nio.lsp.types.LSPAny A data entry field that is preserved between a type hierarchy prepare and supertypes or subtypes requests. It could also be used to identify the type hierarchy in the server, helping improve the performance on resolving supertypes and subtypes.

--- A completion item represents a text snippet that is
--- proposed to complete text that is being typed.
---@class nio.lsp.types.CompletionItem
---@field label string The label of this completion item.  The label property is also by default the text that is inserted when selecting this completion.  If label details are provided the label itself should be an unqualified name of the completion item.
---@field labelDetails? nio.lsp.types.CompletionItemLabelDetails Additional details for the label  @since 3.17.0
---@field kind? nio.lsp.types.CompletionItemKind The kind of this completion item. Based of the kind an icon is chosen by the editor.
---@field tags? nio.lsp.types.CompletionItemTag[] Tags for this completion item.  @since 3.15.0
---@field detail? string A human-readable string with additional information about this item, like type or symbol information.
---@field documentation? string|nio.lsp.types.MarkupContent A human-readable string that represents a doc-comment.
---@field deprecated? boolean Indicates if this item is deprecated. @deprecated Use `tags` instead.
---@field preselect? boolean Select this item when showing.  *Note* that only one completion item can be selected and that the tool / client decides which item that is. The rule is that the *first* item of those that match best is selected.
---@field sortText? string A string that should be used when comparing this item with other items. When `falsy` the [label](#CompletionItem.label) is used.
---@field filterText? string A string that should be used when filtering a set of completion items. When `falsy` the [label](#CompletionItem.label) is used.
---@field insertText? string A string that should be inserted into a document when selecting this completion. When `falsy` the [label](#CompletionItem.label) is used.  The `insertText` is subject to interpretation by the client side. Some tools might not take the string literally. For example VS Code when code complete is requested in this example `con<cursor position>` and a completion item with an `insertText` of `console` is provided it will only insert `sole`. Therefore it is recommended to use `textEdit` instead since it avoids additional client side interpretation.
---@field insertTextFormat? nio.lsp.types.InsertTextFormat The format of the insert text. The format applies to both the `insertText` property and the `newText` property of a provided `textEdit`. If omitted defaults to `InsertTextFormat.PlainText`.  Please note that the insertTextFormat doesn't apply to `additionalTextEdits`.
---@field insertTextMode? nio.lsp.types.InsertTextMode How whitespace and indentation is handled during completion item insertion. If not provided the clients default value depends on the `textDocument.completion.insertTextMode` client capability.  @since 3.16.0
---@field textEdit? nio.lsp.types.TextEdit|nio.lsp.types.InsertReplaceEdit An [edit](#TextEdit) which is applied to a document when selecting this completion. When an edit is provided the value of [insertText](#CompletionItem.insertText) is ignored.  Most editors support two different operations when accepting a completion item. One is to insert a completion text and the other is to replace an existing text with a completion text. Since this can usually not be predetermined by a server it can report both ranges. Clients need to signal support for `InsertReplaceEdits` via the `textDocument.completion.insertReplaceSupport` client capability property.  *Note 1:* The text edit's range as well as both ranges from an insert replace edit must be a [single line] and they must contain the position at which completion has been requested. *Note 2:* If an `InsertReplaceEdit` is returned the edit's insert range must be a prefix of the edit's replace range, that means it must be contained and starting at the same position.  @since 3.16.0 additional type `InsertReplaceEdit`
---@field textEditText? string The edit text used if the completion item is part of a CompletionList and CompletionList defines an item default for the text edit range.  Clients will only honor this property if they opt into completion list item defaults using the capability `completionList.itemDefaults`.  If not provided and a list's default range is provided the label property is used as a text.  @since 3.17.0
---@field additionalTextEdits? nio.lsp.types.TextEdit[] An optional array of additional [text edits](#TextEdit) that are applied when selecting this completion. Edits must not overlap (including the same insert position) with the main [edit](#CompletionItem.textEdit) nor with themselves.  Additional text edits should be used to change text unrelated to the current cursor position (for example adding an import statement at the top of the file if the completion item will insert an unqualified type).
---@field commitCharacters? string[] An optional set of characters that when pressed while this completion is active will accept it first and then type that character. *Note* that all commit characters should have `length=1` and that superfluous characters will be ignored.
---@field command? nio.lsp.types.Command An optional [command](#Command) that is executed *after* inserting this completion. *Note* that additional modifications to the current document should be described with the [additionalTextEdits](#CompletionItem.additionalTextEdits)-property.
---@field data? nio.lsp.types.LSPAny A data entry field that is preserved on a completion item between a [CompletionRequest](#CompletionRequest) and a [CompletionResolveRequest](#CompletionResolveRequest).

--- Represents a collection of [completion items](#CompletionItem) to be presented
--- in the editor.
---@class nio.lsp.types.CompletionList
---@field isIncomplete boolean This list it not complete. Further typing results in recomputing this list.  Recomputed lists have all their items replaced (not appended) in the incomplete completion sessions.
---@field itemDefaults? nio.lsp.types.Structure34 In many cases the items of an actual completion result share the same value for properties like `commitCharacters` or the range of a text edit. A completion list can therefore define item defaults which will be used if a completion item itself doesn't specify the value.  If a completion list specifies a default value and a completion item also specifies a corresponding value the one from the item is used.  Servers are only allowed to return default values if the client signals support for this via the `completionList.itemDefaults` capability.  @since 3.17.0
---@field items nio.lsp.types.CompletionItem[] The completion items.

--- Completion parameters
---@class nio.lsp.types.CompletionParams : nio.lsp.types.TextDocumentPositionParams,nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field context? nio.lsp.types.CompletionContext The completion context. This is only available it the client specifies to send this using the client capability `textDocument.completion.contextSupport === true`

--- Registration options for a [CompletionRequest](#CompletionRequest).
---@class nio.lsp.types.CompletionRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.CompletionOptions

--- Client capabilities specific to diagnostic pull requests.
---
--- @since 3.17.0
---@class nio.lsp.types.DiagnosticClientCapabilities
---@field dynamicRegistration? boolean Whether implementation supports dynamic registration. If this is set to `true` the client supports the new `(TextDocumentRegistrationOptions & StaticRegistrationOptions)` return value for the corresponding server capability as well.
---@field relatedDocumentSupport? boolean Whether the clients supports related documents for document diagnostic pulls.

--- Moniker definition to match LSIF 0.5 moniker definition.
---
--- @since 3.16.0
---@class nio.lsp.types.Moniker
---@field scheme string The scheme of the moniker. For example tsc or .Net
---@field identifier string The identifier of the moniker. The value is opaque in LSIF however schema owners are allowed to define the structure if they want.
---@field unique nio.lsp.types.UniquenessLevel The scope in which the moniker is unique
---@field kind? nio.lsp.types.MonikerKind The moniker kind if known.

--- The result of a hover request.
---@class nio.lsp.types.Hover
---@field contents nio.lsp.types.MarkupContent|nio.lsp.types.MarkedString|nio.lsp.types.MarkedString[] The hover's content
---@field range? nio.lsp.types.Range An optional range inside the text document that is used to visualize the hover, e.g. by changing the background color.

--- Parameters for a [HoverRequest](#HoverRequest).
---@class nio.lsp.types.HoverParams : nio.lsp.types.TextDocumentPositionParams,nio.lsp.types.WorkDoneProgressParams

--- Registration options for a [HoverRequest](#HoverRequest).
---@class nio.lsp.types.HoverRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.HoverOptions

--- Show message request client capabilities
---@class nio.lsp.types.ShowMessageRequestClientCapabilities
---@field messageActionItem? nio.lsp.types.Structure35 Capabilities specific to the `MessageActionItem` type.

--- Signature help represents the signature of something
--- callable. There can be multiple signature but only one
--- active and only one active parameter.
---@class nio.lsp.types.SignatureHelp
---@field signatures nio.lsp.types.SignatureInformation[] One or more signatures.
---@field activeSignature? integer The active signature. If omitted or the value lies outside the range of `signatures` the value defaults to zero or is ignored if the `SignatureHelp` has no signatures.  Whenever possible implementors should make an active decision about the active signature and shouldn't rely on a default value.  In future version of the protocol this property might become mandatory to better express this.
---@field activeParameter? integer The active parameter of the active signature. If omitted or the value lies outside the range of `signatures[activeSignature].parameters` defaults to 0 if the active signature has parameters. If the active signature has no parameters it is ignored. In future version of the protocol this property might become mandatory to better express the active parameter if the active signature does have any.

--- Parameters for a [SignatureHelpRequest](#SignatureHelpRequest).
---@class nio.lsp.types.SignatureHelpParams : nio.lsp.types.TextDocumentPositionParams,nio.lsp.types.WorkDoneProgressParams
---@field context? nio.lsp.types.SignatureHelpContext The signature help context. This is only available if the client specifies to send this using the client capability `textDocument.signatureHelp.contextSupport === true`  @since 3.15.0

--- Registration options for a [SignatureHelpRequest](#SignatureHelpRequest).
---@class nio.lsp.types.SignatureHelpRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.SignatureHelpOptions

--- Parameters for a [DefinitionRequest](#DefinitionRequest).
---@class nio.lsp.types.DefinitionParams : nio.lsp.types.TextDocumentPositionParams,nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams

--- Registration options for a [DefinitionRequest](#DefinitionRequest).
---@class nio.lsp.types.DefinitionRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.DefinitionOptions

---@class nio.lsp.types.WorkspaceFoldersInitializeParams
---@field workspaceFolders? nio.lsp.types.WorkspaceFolder[]|nil The workspace folders configured in the client when the server starts.  This property is only available if the client supports workspace folders. It can be `null` if the client supports workspace folders but none are configured.  @since 3.6.0

--- Parameters for a [ReferencesRequest](#ReferencesRequest).
---@class nio.lsp.types.ReferenceParams : nio.lsp.types.TextDocumentPositionParams,nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field context nio.lsp.types.ReferenceContext

--- Registration options for a [ReferencesRequest](#ReferencesRequest).
---@class nio.lsp.types.ReferenceRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.ReferenceOptions
---@alias nio.lsp.types.NotebookDocumentFilter nio.lsp.types.Structure36|nio.lsp.types.Structure37|nio.lsp.types.Structure38

--- A document highlight is a range inside a text document which deserves
--- special attention. Usually a document highlight is visualized by changing
--- the background color of its range.
---@class nio.lsp.types.DocumentHighlight
---@field range nio.lsp.types.Range The range this highlight applies to.
---@field kind? nio.lsp.types.DocumentHighlightKind The highlight kind, default is [text](#DocumentHighlightKind.Text).

--- Parameters for a [DocumentHighlightRequest](#DocumentHighlightRequest).
---@class nio.lsp.types.DocumentHighlightParams : nio.lsp.types.TextDocumentPositionParams,nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams

--- Registration options for a [DocumentHighlightRequest](#DocumentHighlightRequest).
---@class nio.lsp.types.DocumentHighlightRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.DocumentHighlightOptions

--- A range in a text document expressed as (zero-based) start and end positions.
---
--- If you want to specify a range that contains a line including the line ending
--- character(s) then use an end position denoting the start of the next line.
--- For example:
--- ```ts
--- {
---     start: { line: 5, character: 23 }
---     end : { line 6, character : 0 }
--- }
--- ```
---@class nio.lsp.types.Range
---@field start nio.lsp.types.Position The range's start position.
---@field end nio.lsp.types.Position The range's end position.

--- Represents information about programming constructs like variables, classes,
--- interfaces etc.
---@class nio.lsp.types.SymbolInformation : nio.lsp.types.BaseSymbolInformation
---@field deprecated? boolean Indicates if this symbol is deprecated.  @deprecated Use tags instead
---@field location nio.lsp.types.Location The location of this symbol. The location's range is used by a tool to reveal the location in the editor. If the symbol is selected in the tool the range's start information is used to position the cursor. So the range usually spans more than the actual symbol's name and does normally include things like visibility modifiers.  The range doesn't have to denote a node range in the sense of an abstract syntax tree. It can therefore not be used to re-construct a hierarchy of the symbols.

--- Represents programming constructs like variables, classes, interfaces etc.
--- that appear in a document. Document symbols can be hierarchical and they
--- have two ranges: one that encloses its definition and one that points to
--- its most interesting range, e.g. the range of an identifier.
---@class nio.lsp.types.DocumentSymbol
---@field name string The name of this symbol. Will be displayed in the user interface and therefore must not be an empty string or a string only consisting of white spaces.
---@field detail? string More detail for this symbol, e.g the signature of a function.
---@field kind nio.lsp.types.SymbolKind The kind of this symbol.
---@field tags? nio.lsp.types.SymbolTag[] Tags for this document symbol.  @since 3.16.0
---@field deprecated? boolean Indicates if this symbol is deprecated.  @deprecated Use tags instead
---@field range nio.lsp.types.Range The range enclosing this symbol not including leading/trailing whitespace but everything else like comments. This information is typically used to determine if the clients cursor is inside the symbol to reveal in the symbol in the UI.
---@field selectionRange nio.lsp.types.Range The range that should be selected and revealed when this symbol is being picked, e.g the name of a function. Must be contained by the `range`.
---@field children? nio.lsp.types.DocumentSymbol[] Children of this symbol, e.g. properties of a class.

--- Parameters for a [DocumentSymbolRequest](#DocumentSymbolRequest).
---@class nio.lsp.types.DocumentSymbolParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The text document.

--- Registration options for a [DocumentSymbolRequest](#DocumentSymbolRequest).
---@class nio.lsp.types.DocumentSymbolRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.DocumentSymbolOptions

--- Save options.
---@class nio.lsp.types.SaveOptions
---@field includeText? boolean The client is supposed to include the content on save.

--- The data type of the ResponseError if the
--- initialize request fails.
---@class nio.lsp.types.InitializeError
---@field retry boolean Indicates whether the client execute the following retry logic: (1) show the message provided by the ResponseError to the user (2) user selects retry or cancel (3) if user selected retry the initialize method is sent again.

--- The parameters of a [CodeActionRequest](#CodeActionRequest).
---@class nio.lsp.types.CodeActionParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The document in which the command was invoked.
---@field range nio.lsp.types.Range The range for which the command was invoked.
---@field context nio.lsp.types.CodeActionContext Context carrying additional information.

--- Registration options for a [CodeActionRequest](#CodeActionRequest).
---@class nio.lsp.types.CodeActionRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.CodeActionOptions

--- Represents programming constructs like functions or constructors in the context
--- of call hierarchy.
---
--- @since 3.16.0
---@class nio.lsp.types.CallHierarchyItem
---@field name string The name of this item.
---@field kind nio.lsp.types.SymbolKind The kind of this item.
---@field tags? nio.lsp.types.SymbolTag[] Tags for this item.
---@field detail? string More detail for this item, e.g. the signature of a function.
---@field uri nio.lsp.types.DocumentUri The resource identifier of this item.
---@field range nio.lsp.types.Range The range enclosing this symbol not including leading/trailing whitespace but everything else, e.g. comments and code.
---@field selectionRange nio.lsp.types.Range The range that should be selected and revealed when this symbol is being picked, e.g. the name of a function. Must be contained by the [`range`](#CallHierarchyItem.range).
---@field data? nio.lsp.types.LSPAny A data entry field that is preserved between a call hierarchy prepare and incoming calls or outgoing calls requests.

--- A workspace edit represents changes to many resources managed in the workspace. The edit
--- should either provide `changes` or `documentChanges`. If documentChanges are present
--- they are preferred over `changes` if the client can handle versioned document edits.
---
--- Since version 3.13.0 a workspace edit can contain resource operations as well. If resource
--- operations are present clients need to execute the operations in the order in which they
--- are provided. So a workspace edit for example can consist of the following two changes:
--- (1) a create file a.txt and (2) a text document edit which insert text into file a.txt.
---
--- An invalid sequence (e.g. (1) delete file a.txt and (2) insert text into file a.txt) will
--- cause failure of the operation. How the client recovers from the failure is described by
--- the client capability: `workspace.workspaceEdit.failureHandling`
---@class nio.lsp.types.WorkspaceEdit
---@field changes? table<nio.lsp.types.DocumentUri, nio.lsp.types.TextEdit[]> Holds changes to existing resources.
---@field documentChanges? nio.lsp.types.TextDocumentEdit|nio.lsp.types.CreateFile|nio.lsp.types.RenameFile|nio.lsp.types.DeleteFile[] Depending on the client capability `workspace.workspaceEdit.resourceOperations` document changes are either an array of `TextDocumentEdit`s to express changes to n different text documents where each text document edit addresses a specific version of a text document. Or it can contain above `TextDocumentEdit`s mixed with create, rename and delete file / folder operations.  Whether a client supports versioned document edits is expressed via `workspace.workspaceEdit.documentChanges` client capability.  If a client neither supports `documentChanges` nor `workspace.workspaceEdit.resourceOperations` then only plain `TextEdit`s using the `changes` property are supported.
---@field changeAnnotations? table<nio.lsp.types.ChangeAnnotationIdentifier, nio.lsp.types.ChangeAnnotation> A map of change annotations that can be referenced in `AnnotatedTextEdit`s or create, rename and delete file / folder operations.  Whether clients honor this property depends on the client capability `workspace.changeAnnotationSupport`.  @since 3.16.0

--- A special workspace symbol that supports locations without a range.
---
--- See also SymbolInformation.
---
--- @since 3.17.0
---@class nio.lsp.types.WorkspaceSymbol : nio.lsp.types.BaseSymbolInformation
---@field location nio.lsp.types.Location|nio.lsp.types.Structure39 The location of the symbol. Whether a server is allowed to return a location without a range depends on the client capability `workspace.symbol.resolveSupport`.  See SymbolInformation#location for more details.
---@field data? nio.lsp.types.LSPAny A data entry field that is preserved on a workspace symbol between a workspace symbol request and a workspace symbol resolve request.

--- The parameters of a [WorkspaceSymbolRequest](#WorkspaceSymbolRequest).
---@class nio.lsp.types.WorkspaceSymbolParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field query string A query string to filter symbols by. Clients may send an empty string here to request all symbols.

--- Registration options for a [WorkspaceSymbolRequest](#WorkspaceSymbolRequest).
---@class nio.lsp.types.WorkspaceSymbolRegistrationOptions : nio.lsp.types.WorkspaceSymbolOptions

---@class nio.lsp.types.Structure35
---@field additionalPropertiesSupport? boolean Whether the client supports additional attributes which are preserved and send back to the server in the request's response.

---@class nio.lsp.types.LinkedEditingRangeRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.LinkedEditingRangeOptions,nio.lsp.types.StaticRegistrationOptions
---@alias nio.lsp.types.ResourceOperationKind "create"|"rename"|"delete"

---@class nio.lsp.types.FoldingRangeRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.FoldingRangeOptions,nio.lsp.types.StaticRegistrationOptions

--- A code lens represents a [command](#Command) that should be shown along with
--- source text, like the number of references, a way to run tests, etc.
---
--- A code lens is _unresolved_ when no command is associated to it. For performance
--- reasons the creation of a code lens and resolving should be done in two stages.
---@class nio.lsp.types.CodeLens
---@field range nio.lsp.types.Range The range in which this code lens is valid. Should only span a single line.
---@field command? nio.lsp.types.Command The command this code lens represents.
---@field data? nio.lsp.types.LSPAny A data entry field that is preserved on a code lens item between a [CodeLensRequest](#CodeLensRequest) and a [CodeLensResolveRequest] (#CodeLensResolveRequest)

--- The parameters of a [CodeLensRequest](#CodeLensRequest).
---@class nio.lsp.types.CodeLensParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The document to request code lens for.

--- Registration options for a [CodeLensRequest](#CodeLensRequest).
---@class nio.lsp.types.CodeLensRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.CodeLensOptions

--- A selection range represents a part of a selection hierarchy. A selection range
--- may have a parent selection range that contains it.
---@class nio.lsp.types.SelectionRange
---@field range nio.lsp.types.Range The [range](#Range) of this selection range.
---@field parent? nio.lsp.types.SelectionRange The parent selection range containing this range. Therefore `parent.range` must contain `this.range`.

--- Call hierarchy options used during static or dynamic registration.
---
--- @since 3.16.0
---@class nio.lsp.types.CallHierarchyRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.CallHierarchyOptions,nio.lsp.types.StaticRegistrationOptions

--- Represents a diagnostic, such as a compiler error or warning. Diagnostic objects
--- are only valid in the scope of a resource.
---@class nio.lsp.types.Diagnostic
---@field range nio.lsp.types.Range The range at which the message applies
---@field severity? nio.lsp.types.DiagnosticSeverity The diagnostic's severity. Can be omitted. If omitted it is up to the client to interpret diagnostics as error, warning, info or hint.
---@field code? integer|string The diagnostic's code, which usually appear in the user interface.
---@field codeDescription? nio.lsp.types.CodeDescription An optional property to describe the error code. Requires the code field (above) to be present/not null.  @since 3.16.0
---@field source? string A human-readable string describing the source of this diagnostic, e.g. 'typescript' or 'super lint'. It usually appears in the user interface.
---@field message string The diagnostic's message. It usually appears in the user interface
---@field tags? nio.lsp.types.DiagnosticTag[] Additional metadata about the diagnostic.  @since 3.15.0
---@field relatedInformation? nio.lsp.types.DiagnosticRelatedInformation[] An array of related diagnostic information, e.g. when symbol-names within a scope collide all definitions can be marked via this property.
---@field data? nio.lsp.types.LSPAny A data entry field that is preserved between a `textDocument/publishDiagnostics` notification and `textDocument/codeAction` request.  @since 3.16.0

--- A code action represents a change that can be performed in code, e.g. to fix a problem or
--- to refactor code.
---
--- A CodeAction must set either `edit` and/or a `command`. If both are supplied, the `edit` is applied first, then the `command` is executed.
---@class nio.lsp.types.CodeAction
---@field title string A short, human-readable, title for this code action.
---@field kind? nio.lsp.types.CodeActionKind The kind of the code action.  Used to filter code actions.
---@field diagnostics? nio.lsp.types.Diagnostic[] The diagnostics that this code action resolves.
---@field isPreferred? boolean Marks this as a preferred action. Preferred actions are used by the `auto fix` command and can be targeted by keybindings.  A quick fix should be marked preferred if it properly addresses the underlying error. A refactoring should be marked preferred if it is the most reasonable choice of actions to take.  @since 3.15.0
---@field disabled? nio.lsp.types.Structure40 Marks that the code action cannot currently be applied.  Clients should follow the following guidelines regarding disabled code actions:    - Disabled code actions are not shown in automatic [lightbulbs](https://code.visualstudio.com/docs/editor/editingevolved#_code-action)     code action menus.    - Disabled actions are shown as faded out in the code action menu when the user requests a more specific type     of code action, such as refactorings.    - If the user has a [keybinding](https://code.visualstudio.com/docs/editor/refactoring#_keybindings-for-code-actions)     that auto applies a code action and only disabled code actions are returned, the client should show the user an     error message with `reason` in the editor.  @since 3.16.0
---@field edit? nio.lsp.types.WorkspaceEdit The workspace edit this code action performs.
---@field command? nio.lsp.types.Command A command this code action executes. If a code action provides an edit and a command, first the edit is executed and then the command.
---@field data? nio.lsp.types.LSPAny A data entry field that is preserved on a code action between a `textDocument/codeAction` and a `codeAction/resolve` request.  @since 3.16.0

--- A parameter literal used in selection range requests.
---@class nio.lsp.types.SelectionRangeParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The text document.
---@field positions nio.lsp.types.Position[] The positions inside the text document.

--- A document link is a range in a text document that links to an internal or external resource, like another
--- text document or a web site.
---@class nio.lsp.types.DocumentLink
---@field range nio.lsp.types.Range The range this link applies to.
---@field target? string The uri this link points to. If missing a resolve request is sent later.
---@field tooltip? string The tooltip text when you hover over this link.  If a tooltip is provided, is will be displayed in a string that includes instructions on how to trigger the link, such as `{0} (ctrl + click)`. The specific instructions vary depending on OS, user settings, and localization.  @since 3.15.0
---@field data? nio.lsp.types.LSPAny A data entry field that is preserved on a document link between a DocumentLinkRequest and a DocumentLinkResolveRequest.

--- The parameters of a [DocumentLinkRequest](#DocumentLinkRequest).
---@class nio.lsp.types.DocumentLinkParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The document to provide document links for.

--- Registration options for a [DocumentLinkRequest](#DocumentLinkRequest).
---@class nio.lsp.types.DocumentLinkRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.DocumentLinkOptions

--- General text document registration options.
---@class nio.lsp.types.TextDocumentRegistrationOptions
---@field documentSelector nio.lsp.types.DocumentSelector|nil A document selector to identify the scope of the registration. If set to null the document selector provided on the client side will be used.

---@class nio.lsp.types.PartialResultParams
---@field partialResultToken? nio.lsp.types.ProgressToken An optional token that a server can use to report partial results (e.g. streaming) to the client.
--- How a completion was triggered
---@alias nio.lsp.types.CompletionTriggerKind 1|2|3

--- The parameters of a [DocumentFormattingRequest](#DocumentFormattingRequest).
---@class nio.lsp.types.DocumentFormattingParams : nio.lsp.types.WorkDoneProgressParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The document to format.
---@field options nio.lsp.types.FormattingOptions The format options.

--- Registration options for a [DocumentFormattingRequest](#DocumentFormattingRequest).
---@class nio.lsp.types.DocumentFormattingRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.DocumentFormattingOptions

--- The parameter of a `callHierarchy/incomingCalls` request.
---
--- @since 3.16.0
---@class nio.lsp.types.CallHierarchyIncomingCallsParams : nio.lsp.types.WorkDoneProgressParams,nio.lsp.types.PartialResultParams
---@field item nio.lsp.types.CallHierarchyItem

--- The parameters of a [DocumentRangeFormattingRequest](#DocumentRangeFormattingRequest).
---@class nio.lsp.types.DocumentRangeFormattingParams : nio.lsp.types.WorkDoneProgressParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The document to format.
---@field range nio.lsp.types.Range The range to format
---@field options nio.lsp.types.FormattingOptions The format options

--- Registration options for a [DocumentRangeFormattingRequest](#DocumentRangeFormattingRequest).
---@class nio.lsp.types.DocumentRangeFormattingRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.DocumentRangeFormattingOptions

--- Represents a color in RGBA space.
---@class nio.lsp.types.Color
---@field red number The red component of this color in the range [0-1].
---@field green number The green component of this color in the range [0-1].
---@field blue number The blue component of this color in the range [0-1].
---@field alpha number The alpha component of this color in the range [0-1].

---@class nio.lsp.types.WorkspaceEditClientCapabilities
---@field documentChanges? boolean The client supports versioned document changes in `WorkspaceEdit`s
---@field resourceOperations? nio.lsp.types.ResourceOperationKind[] The resource operations the client supports. Clients should at least support 'create', 'rename' and 'delete' files and folders.  @since 3.13.0
---@field failureHandling? nio.lsp.types.FailureHandlingKind The failure handling strategy of a client if applying the workspace edit fails.  @since 3.13.0
---@field normalizesLineEndings? boolean Whether the client normalizes line endings to the client specific setting. If set to `true` the client will normalize line ending characters in a workspace edit to the client-specified new line character.  @since 3.16.0
---@field changeAnnotationSupport? nio.lsp.types.Structure41 Whether the client in general supports change annotations on text edits, create file, rename file and delete file changes.  @since 3.16.0

--- The parameters of a [DocumentOnTypeFormattingRequest](#DocumentOnTypeFormattingRequest).
---@class nio.lsp.types.DocumentOnTypeFormattingParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The document to format.
---@field position nio.lsp.types.Position The position around which the on type formatting should happen. This is not necessarily the exact position where the character denoted by the property `ch` got typed.
---@field ch string The character that has been typed that triggered the formatting on type request. That is not necessarily the last character that got inserted into the document since the client could auto insert characters as well (e.g. like automatic brace completion).
---@field options nio.lsp.types.FormattingOptions The formatting options.

--- Registration options for a [DocumentOnTypeFormattingRequest](#DocumentOnTypeFormattingRequest).
---@class nio.lsp.types.DocumentOnTypeFormattingRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.DocumentOnTypeFormattingOptions

---@class nio.lsp.types.DidChangeConfigurationClientCapabilities
---@field dynamicRegistration? boolean Did change configuration notification supports dynamic registration.

--- The parameters of a [RenameRequest](#RenameRequest).
---@class nio.lsp.types.RenameParams : nio.lsp.types.WorkDoneProgressParams
---@field textDocument nio.lsp.types.TextDocumentIdentifier The document to rename.
---@field position nio.lsp.types.Position The position at which this request was sent.
---@field newName string The new name of the symbol. If the given name is not valid the request must return a [ResponseError](#ResponseError) with an appropriate message set.

--- Registration options for a [RenameRequest](#RenameRequest).
---@class nio.lsp.types.RenameRegistrationOptions : nio.lsp.types.TextDocumentRegistrationOptions,nio.lsp.types.RenameOptions

---@class nio.lsp.types.FileSystemWatcher
---@field globPattern nio.lsp.types.GlobPattern The glob pattern to watch. See {@link GlobPattern glob pattern} for more detail.  @since 3.17.0 support for relative patterns.
---@field kind? nio.lsp.types.WatchKind The kind of events of interest. If omitted it defaults to WatchKind.Create | WatchKind.Change | WatchKind.Delete which is 7.

--- Client capabilities for a [WorkspaceSymbolRequest](#WorkspaceSymbolRequest).
---@class nio.lsp.types.WorkspaceSymbolClientCapabilities
---@field dynamicRegistration? boolean Symbol request supports dynamic registration.
---@field symbolKind? nio.lsp.types.Structure42 Specific capabilities for the `SymbolKind` in the `workspace/symbol` request.
---@field tagSupport? nio.lsp.types.Structure43 The client supports tags on `SymbolInformation`. Clients supporting tags have to handle unknown tags gracefully.  @since 3.16.0
---@field resolveSupport? nio.lsp.types.Structure44 The client support partial workspace symbols. The client will send the request `workspaceSymbol/resolve` to the server to resolve additional properties.  @since 3.17.0

---@class nio.lsp.types.PrepareRenameParams : nio.lsp.types.TextDocumentPositionParams,nio.lsp.types.WorkDoneProgressParams

--- Inlay hint options used during static registration.
---
--- @since 3.17.0
---@class nio.lsp.types.InlayHintOptions : nio.lsp.types.WorkDoneProgressOptions
---@field resolveProvider? boolean The server provides support to resolve additional information for an inlay hint item.

--- The client capabilities of a [ExecuteCommandRequest](#ExecuteCommandRequest).
---@class nio.lsp.types.ExecuteCommandClientCapabilities
---@field dynamicRegistration? boolean Execute command supports dynamic registration.

--- The parameters of a [ExecuteCommandRequest](#ExecuteCommandRequest).
---@class nio.lsp.types.ExecuteCommandParams : nio.lsp.types.WorkDoneProgressParams
---@field command string The identifier of the actual command handler.
---@field arguments? nio.lsp.types.LSPAny[] Arguments that the command should be invoked with.

--- Registration options for a [ExecuteCommandRequest](#ExecuteCommandRequest).
---@class nio.lsp.types.ExecuteCommandRegistrationOptions : nio.lsp.types.ExecuteCommandOptions

--- Provider options for a [DocumentOnTypeFormattingRequest](#DocumentOnTypeFormattingRequest).
---@class nio.lsp.types.DocumentOnTypeFormattingOptions
---@field firstTriggerCharacter string A character on which formatting should be triggered, like `{`.
---@field moreTriggerCharacter? string[] More trigger characters.
