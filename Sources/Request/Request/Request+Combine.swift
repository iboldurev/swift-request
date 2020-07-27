//
//  Request+Combine.swift
//  
//
//  Created by Carson Katri on 7/27/20.
//

import Foundation
import Combine
import Json

extension AnyRequest {
    public func receive<S>(subscriber: S) where S : Subscriber, S.Failure == Failure, S.Input == Self.Output {
        buildSession()
            .subscribe(subscriber)
    }
}

extension AnyRequest: Subscriber {
    public typealias Input = (data: Data, response: URLResponse)
    
    public func receive(subscription: Subscription) {
        subscription.request(.max(1))
    }
    
    public func receive(_ input: Input) -> Subscribers.Demand {
        if let res = input.response as? HTTPURLResponse {
            let statusCode = res.statusCode
            if statusCode < 200 || statusCode >= 300 {
                if let onError = self.onError {
                    onError(RequestError(statusCode: statusCode, error: input.data))
                    return .none
                }
            }
        }
        if let onData = self.onData {
            onData(input.data)
        }
        if let onString = self.onString {
            if let string = String(data: input.data, encoding: .utf8) {
                onString(string)
            }
        }
        if let onJson = self.onJson {
            if let string = String(data: input.data, encoding: .utf8) {
                if let json = try? Json(string) {
                    onJson(json)
                }
            }
        }
        if let onObject = self.onObject {
            if let decoded = try? JSONDecoder().decode(ResponseType.self, from: input.data) {
                onObject(decoded)
            }
        }
        return .none
    }
    
    public func receive(completion: Subscribers.Completion<Error>) {
        switch completion {
        case .failure(let err): onError?(err)
        case .finished: return
        }
    }
}

extension AnyRequest {
    struct UpdateSubscriber: Subscriber {
        let combineIdentifier: CombineIdentifier = CombineIdentifier()
        let request: AnyRequest<ResponseType>
        
        typealias Input = Void
        typealias Failure = Never
        
        func receive(subscription: Subscription) {
            subscription.request(.unlimited)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            request.call()
            return .none
        }
        
        func receive(completion: Subscribers.Completion<Failure>) {
            return
        }
    }
}