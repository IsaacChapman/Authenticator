//
//  Root.swift
//  Authenticator
//
//  Copyright (c) 2015 Authenticator authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import OneTimePassword

struct Root: Component {
    private var tokenList: TokenList
    private var modal: Modal

    private enum Modal {
        case None
        case Scanner
        case EntryForm(TokenEntryForm)
        case EditForm(TokenEditForm)

        var viewModel: RootViewModel.ModalViewModel {
            switch self {
            case .None:
                return .None
            case .Scanner:
                return .Scanner
            case .EntryForm(let form):
                return .EntryForm(form.viewModel)
            case .EditForm(let form):
                return .EditForm(form.viewModel)
            }
        }
    }

    init(persistentTokens: [PersistentToken]) {
        tokenList = TokenList(persistentTokens: persistentTokens)
        modal = .None
    }
}

// MARK: View

extension Root {
    typealias ViewModel = RootViewModel

    var viewModel: ViewModel {
        return ViewModel(
            tokenList: tokenList.viewModel,
            modal: modal.viewModel
        )
    }
}

// MARK: Update

extension Root {
    enum Action {
        case UpdateTokenList([PersistentToken])

        case TokenListAction(TokenList.Action)
        case TokenEntryFormAction(TokenEntryForm.Action)
        case TokenEditFormAction(TokenEditForm.Action)

        case TokenScannerEffect(TokenScannerViewController.Effect)
    }

    enum Effect {
        case AddToken(Token)
        case SaveToken(Token, PersistentToken)
        case UpdatePersistentToken(PersistentToken)
        case MoveToken(fromIndex: Int, toIndex: Int)
        case DeletePersistentToken(PersistentToken)
    }

    @warn_unused_result
    mutating func update(action: Action) -> Effect? {
        switch action {
        case .UpdateTokenList(let persistentTokens):
            let action: TokenList.Action = .UpdateTokenList(persistentTokens)
            return handleTokenListAction(action)

        case .TokenListAction(let action):
            return handleTokenListAction(action)
        case .TokenEntryFormAction(let action):
            return handleTokenEntryAction(action)
        case .TokenEditFormAction(let action):
            return handleTokenEditAction(action)
        case .TokenScannerEffect(let effect):
            return handleTokenScannerEffect(effect)
        }
    }

    @warn_unused_result
    private mutating func handleTokenListAction(action: TokenList.Action) -> Effect? {
        let effect = tokenList.update(action)
        if let effect = effect {
            return handleTokenListEffect(effect)
        }
        return nil
    }

    @warn_unused_result
    private mutating func handleTokenListEffect(effect: TokenList.Effect) -> Effect? {
        switch effect {
        case .BeginTokenEntry:
            if QRScanner.deviceCanScan {
                modal = .Scanner
            } else {
                modal = .EntryForm(TokenEntryForm())
            }
            return nil

        case .BeginTokenEdit(let persistentToken):
            let form = TokenEditForm(persistentToken: persistentToken)
            modal = .EditForm(form)
            return nil

        case .UpdateToken(let persistentToken):
            return .UpdatePersistentToken(persistentToken)

        case let .MoveToken(fromIndex, toIndex):
            return .MoveToken(fromIndex: fromIndex, toIndex: toIndex)

        case .DeletePersistentToken(let persistentToken):
            return .DeletePersistentToken(persistentToken)
        }
    }

    @warn_unused_result
    private mutating func handleTokenEntryAction(action: TokenEntryForm.Action) -> Effect? {
        if case .EntryForm(let form) = modal {
            var newForm = form
            let effect = newForm.update(action)
            modal = .EntryForm(newForm)
            // Handle the resulting action after committing the changes of the initial action
            if let effect = effect {
                return handleTokenEntryEffect(effect)
            }
        }
        return nil
    }

    @warn_unused_result
    private mutating func handleTokenEntryEffect(effect: TokenEntryForm.Effect) -> Effect? {
        switch effect {
        case .Cancel:
            modal = .None
            return nil

        case .SaveNewToken(let token):
            modal = .None
            return .AddToken(token)
        }
    }

    @warn_unused_result
    private mutating func handleTokenEditAction(action: TokenEditForm.Action) -> Effect? {
        if case .EditForm(let form) = modal {
            var newForm = form
            let effect = newForm.update(action)
            modal = .EditForm(newForm)
            // Handle the resulting effect after committing the changes of the initial action
            if let effect = effect {
                return handleTokenEditEffect(effect)
            }
        }
        return nil
    }

    @warn_unused_result
    private mutating func handleTokenEditEffect(effect: TokenEditForm.Effect) -> Effect? {
        switch effect {
        case .Cancel:
            modal = .None
            return nil

        case let .SaveChanges(token, persistentToken):
            modal = .None
            return .SaveToken(token, persistentToken)
        }
    }

    @warn_unused_result
    private mutating func handleTokenScannerEffect(effect: TokenScannerViewController.Effect) -> Effect? {
        switch effect {
        case .Cancel:
            modal = .None
            return nil

        case .BeginManualTokenEntry:
            modal = .EntryForm(TokenEntryForm())
            return nil

        case .SaveNewToken(let token):
            modal = .None
            return .AddToken(token)
        }
    }
}
