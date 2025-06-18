//
//  HTTPCode.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation
import CoreFoundation

public typealias StatusCode = Int

/// Common HTTP status codes
///
/// Code definitions are [linked here.](http://www.iana.org/assignments/http-status-codes)
public enum HTTPCode: StatusCode, JSONSerializable {
    
    
    //MARK: - 1xx Informational
    
    /// The server has received the request headers and the client should proceed to send the request body.
    case `continue` = 100
    
    /// The requester has asked the server to switch protocols and the server is acknowledging that it will do so.
    case switchingProtocols = 101
    
    /// The server has received and is processing the request, but no response is available yet.
    case processing = 102
    
    //105-199 Unassigned
    
    
    //MARK: - 2xx Success codes
    
    /// The HTTP 200 OK success status response code indicates that the request has succeeded. A 200 response is cacheable by default.
    ///
    /// The meaning of a success depends on the HTTP request method:
    /// - GET: The resource has been fetched and is transmitted in the message body.
    /// - HEAD: The representation headers are included in the response without any message body
    /// - POST: The resource describing the result of the action is transmitted in the message body
    /// - TRACE: The message body contains the request message as received by the server.
    ///
    ///  The successful result of a PUT or a DELETE is often not a 200 OK but a 204 No Content (or a 201 Created when the resource is uploaded for the first time).
    case ok = 200
    
    /// The HTTP 201 Created success status response code indicates that the request has succeeded and has led to the creation of a resource. 
    ///
    /// The new resource, or a description and link to the new resource, is effectively created before the response is sent back and the newly created items are returned in the body of the message, located at either the URL of the request, or at the URL in the value of the Location header.
    /// The common use case of this status code is as the result of a POST request.
    case created = 201
    
    /// The HyperText Transfer Protocol (HTTP) 202 Accepted response status code indicates that the request has been accepted for processing, but the processing has not been completed; in fact, processing may not have started yet. The request might or might not eventually be acted upon, as it might be disallowed when processing actually takes place.
    /// 202 is non-committal, meaning that there is no way for the HTTP to later send an asynchronous response indicating the outcome of processing the request. It is intended for cases where another process or server handles the request, or for batch processing.
    case accepted = 202
    
    /// The HTTP 203 Non-Authoritative Information response status indicates that the request was successful but the enclosed payload has been modified by a transforming proxy from that of the origin server's 200 (OK) response.
    /// The 203 response is similar to the value 214, meaning Transformation Applied, of the Warning header code, which has the additional advantage of being applicable to responses with any status code.
    case nonAuthoritativeInformation = 203
    
    /// The HTTP 204 No Content success status response code indicates that a request has succeeded, but that the client doesn't need to navigate away from its current page.
    ///
    /// This might be used, for example, when implementing "save and continue editing" functionality for a wiki site. In this case a PUT request would be used to save the page, and the 204 No Content response would be sent to indicate that the editor should not be replaced by some other page.
    /// A 204 response is cacheable by default (an ETag header is included in such a response).
    case noContent = 204
    
    /// The HTTP 205 Reset Content response status tells the client to reset the document view, so for example to clear the content of a form, reset a canvas state, or to refresh the UI.
    case resetContent = 205
    
    /// The HTTP 206 Partial Content success status response code indicates that the request has succeeded and the body contains the requested ranges of data, as described in the Range header of the request.
    /// If there is only one range, the Content-Type of the whole response is set to the type of the document, and a Content-Range is provided.
    /// If several ranges are sent back, the Content-Type is set to multipart/byte ranges and each fragment covers one range, with Content-Range and Content-Type describing it.
    case partialContent = 206
    
    
    /// Provides status for multiple independent operations in a single response.
    case multiStatus = 207
    
    /// Indicates that members of a DAV binding have already been enumerated in a previous reply.
    case alreadyReported = 208
    
    //209-225 Unassigned
    
    /// Indicates that the server has fulfilled a GET request for the resource and the response is a representation of the result of one or more instance-manipulations applied to the current instance.
    case imUsed = 226
    
    //MARK: - 3xx Redirection
    
    /// 300 Multiple Choices — Request has multiple options; user-agent or user should choose one of them.
    case multipleChoices = 300
    
    /// 301 Moved Permanently — Resource has been moved permanently to a new URI.
    case moved = 301
    
    /// 302 Found — Resource is temporarily under a different URI.
    case found = 302
    
    /// 303 See Other — Response to be retrieved from another URI using GET method.
    case method = 303
    
    /// 304 Not Modified — Resource has not been modified since last requested.
    case notModified = 304
    
    /// 305 Use Proxy — Resource must be accessed through the proxy given by the Location field.
    case useProxy = 305
    
    //306 Unassigned
    
    /// 307 Temporary Redirect — Temporary redirection; method and body will not be changed.
    case temporaryRedirect = 307
    
    /// 308 Permanent Redirect — Permanent redirection; method and body may be changed.
    case permanentRedirect = 308

    //309-399 Unassigned
    
    
    //MARK: - 4xx Errors
    
    /// The server cannot or will not process the request due to an apparent client error (e.g., malformed request syntax, size too large, invalid request message framing,
    /// or deceptive request routing).
    case badRequest = 400

    /// Authentication is required and has failed or has not yet been provided.  The response must include a WWW-Authenticate header field containing
    /// a challenge applicable to the requested resource.
    case unauthorized = 401
    
    /// Reserved for future use. The original intention was that this code might be used as part of some form of digital cash or micropayment scheme.
    case paymentRequired = 402
    
    /// The request contained valid data and was understood by the server, but the server is refusing action. This may be due to the user not having the necessary permissions for a resource or needing an account of some sort, or attempting a prohibited action (e.g. creating a duplicate record where only one is allowed).
    case forbidden = 403
    
    /// The requested resource could not be found but may be available in the future. Subsequent requests by the client are permissible.
    case resourceNotFound = 404
    
    /// A request method is not supported for the requested resource; for example, a GET request on a form that requires data to be presented via POST,
    /// or a PUT request on a read-only resource.
    case methodNotAllowed = 405
    
    /// The requested resource is capable of generating only content not acceptable according to the Accept headers sent in the request.
    case notAcceptable = 406
    
    /// 407 Proxy Authentication Required — Client must first authenticate itself with the proxy.
    case proxyAuthenticationRequired = 407
    
    /// 408 Request Timeout — Server timed out waiting for the request.
    case requestTimeout = 408
    
    /// 409 Conflict — Request could not be completed due to a conflict with the current state of the target resource.
    case conflict = 409
    
    /// 410 Gone — Resource is no longer available and no forwarding address is known.
    case gone = 410
    
    /// 411 Length Required — Request did not specify the length of its content, which is required.
    case lengthRequired = 411
    
    ///The 412 (Precondition Failed) status code indicates that one or more conditions given in the request header fields evaluated to false when tested on the server [RFC9110, Section 15.5.13](https://www.rfc-editor.org/rfc/rfc9110.html#name-412-precondition-failed)
    case preconditionFailed = 412
    
    /// 413 Payload Too Large — Request entity is larger than limits defined by server.
    case payloadTooLarge = 413
    
    /// 414 URI Too Long — URI provided was too long for the server to process.
    case uriTooLong = 414
    
    /// 415 Unsupported Media Type — Request entity has a media type which is not supported.
    case unsupportedMediaType = 415
    
    /// 416 Range Not Satisfiable — Client has asked for a portion of the file, but the server cannot supply that portion.
    case rangeNotSatisfiable = 416
    
    /// 417 Expectation Failed — Expectation given in Expect header could not be met.
    case expectationFailed = 417
    
    /// I'm a teapot client error response code indicates that the server refuses to brew coffee because it is, permanently, a teapot.
    ///
    /// The sprit of this code can be used to indicate the server does not support this kind of request.
    ///
    /// __See Also__
    ///
    /// [I'm a teapot](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/418)
    case imaTeapot = 418
    
    //419-420 Unassigned
    case misdirectedRequest = 421

    /// The request was well-formed but was unable to be followed due to semantic errors.
    case unprocessableEntity = 422

    /// 423 Locked — Resource that is being accessed is locked.
    case locked = 423
    
    /// 424 Failed Dependency — Request failed due to failure of a previous request.
    case failedDependency = 424
    
    //case toEarly = 425
    
    /// The client should switch to a different protocol such as TLS/1.3, given in the Upgrade header field.
    case upgradeRequired = 426
    
    //427 Unassigned
    
    /// __IMPORTANT__ Actually named '`preconditionRequired`', it has been named here '`conditionRequired`' because of a bug in this file where code (412) was accidentally named '`preconditionRequired`'.  Any code using an older version of Hellfire that implemented '`preconditionRequired`' should replace with '`preconditionFailed` (412)'.
    ///
    /// The 428 status code indicates that the origin server requires the request to be conditional [RFC6585](https://www.iana.org/go/rfc6585)
    case conditionRequired = 428
    
    /// The user has sent too many requests in a given amount of time. Intended for use with rate-limiting schemes.
    case tooManyRequests = 429

    //430 Unassigned
    
    /// 431 Request Header Fields Too Large — Server is unwilling to process the request because its header fields are too large.
    case requestHeaderFieldsTooLarge = 431
    
    //432-450 Unassigned
    
    /// 451 Unavailable For Legal Reasons — Server is denying access to the resource due to legal reasons.
    case unavailableForLegalReasons = 451
    
    //452-499 Unassigned


    //MARK: - 5xx Errors
    
    /// 500 Internal Server Error — Server encountered an unexpected condition and cannot fulfill the request.
    case internalServerError = 500
    
    /// 501 Not Implemented — Server does not support the functionality required to fulfill the request.
    case notImplemented = 501
    
    /// 502 Bad Gateway — Server, while acting as a gateway or proxy, received an invalid response from the upstream server.
    case badGateway = 502
    
    /// 503 Service Unavailable — Server is currently unable to handle the request due to overload or maintenance.
    case serviceUnavailable = 503
    
    /// 504 Gateway Timeout — Server, while acting as a gateway or proxy, did not receive a timely response from the upstream server.
    case gatewayTimeout = 504
    
    /// 505 HTTP Version Not Supported — Server does not support the HTTP protocol version used in the request.
    case httpVersionNotSupported = 505
    
    /// 506 Variant Also Negotiates — Transparent content negotiation for the request results in a circular reference.
    case variantAlsoNegotiates = 506
    
    /// 507 Insufficient Storage — Server is unable to store the representation needed to complete the request.
    case insufficientStorage = 507
    
    /// 508 Loop Detected — Server detected an infinite loop while processing the request.
    case loopDetected = 508
    
    /// 510 Not Extended — Further extensions to the request are required for the server to fulfill it.
    case notExtended = 510
    
    /// 511 Network Authentication Required — Client needs to authenticate to gain network access.
    case networkAuthenticationRequired = 511
    
    //512-599 Unassigned
}

//MARK: - HTTPCode extension
extension HTTPCode {
        
    /// Returns true if `StatusCode` is in the range of 200...299 or if statusCode is nil.
    public static func isOk(_ statusCode: StatusCode?) -> Bool {
        guard let statusCode else { return true }
        return (200...299 ~= statusCode)
    }
}
