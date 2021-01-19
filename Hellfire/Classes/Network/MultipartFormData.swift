//
//  MultipartFormData.swift
//  Hellfire
//
//  Created by Ed Hellyer on 1/14/21.
//

import Foundation
#if os(iOS) || os(watchOS) || os(tvOS)
import MobileCoreServices
#elseif os(macOS)
import CoreServices
#endif

/// MultipartFormData is used to construct the body of a multipart/form-data request.
///
/// For more information on `multipart/form-data` in general, please refer to the RFC-2388 and RFC-2045 specs as well and the w3 form documentation.
/// - https://www.ietf.org/rfc/rfc2388.txt
/// - https://www.ietf.org/rfc/rfc2045.txt
/// - https://www.w3.org/TR/html401/interact/forms.html#h-17.13
public class MultipartFormData {
    
    private class FormPart {
        let headers: Set<HTTPHeader>
        let inputStream: InputStream
        let contentLength: UInt64
        var isInitialBoundary = false
        var isFinalBoundary = false
        
        init(headers: Set<HTTPHeader>, bodyStream: InputStream, bodyContentLength: UInt64) {
            self.headers = headers
            self.inputStream = bodyStream
            self.contentLength = bodyContentLength
        }
    }

    private let initialBoundary: Data
    private let encapsulatedBoundary: Data
    private let finalBoundary: Data
    private let streamBufferSize: Int = 1024
    private var formParts: [FormPart] = []
    private var formPartEncodingError: HellfireError?
    
    private func contentHeaders(withName name: String, fileName: String? = nil, mimeType: String? = nil) -> Set<HTTPHeader> {
        var disposition = "form-data; name=\"\(name)\""
        if let fileName = fileName { disposition += "; filename=\"\(fileName)\"" }
        
        var headers: Set<HTTPHeader> = [.contentDisposition(disposition)]
        if let mimeType = mimeType {
            headers.update(with: .contentType(mimeType))
        }
                
        return headers
    }
    
    
    //MARK: - Private - Body Part Encoding
    
    private func encode(_ formPart: FormPart) throws -> Data {
        var encoded = Data()
        
        let initialOrMidBoundary = formPart.isInitialBoundary ? self.initialBoundary : self.encapsulatedBoundary
        encoded.append(initialOrMidBoundary)
        
        let headerData = encodeHeaders(for: formPart)
        encoded.append(headerData)
        
        let bodyStreamData = try encodeBodyStream(for: formPart)
        encoded.append(bodyStreamData)
        
        if formPart.isFinalBoundary {
            encoded.append(self.finalBoundary)
        }
        
        return encoded
    }
    
    private func encodeHeaders(for formPart: FormPart) -> Data {
        let headerText = formPart.headers.map { "\($0.stringEncoding)\(EncodingHelper.crlf)" }.joined() + EncodingHelper.crlf
        return Data(headerText.utf8)
    }
    
    private func encodeBodyStream(for formPart: FormPart) throws -> Data {
        let inputStream = formPart.inputStream
        inputStream.open()
        defer { inputStream.close() }
        
        var encoded = Data()
        
        while inputStream.hasBytesAvailable {
            var buffer = [UInt8](repeating: 0, count: streamBufferSize)
            let bytesRead = inputStream.read(&buffer, maxLength: streamBufferSize)
            
            if let error = inputStream.streamError {
                throw HellfireError.multipartEncodingFailed(reason: .inputStreamReadFailed(error: error))
            }
            
            if bytesRead > 0 {
                encoded.append(buffer, count: bytesRead)
            } else {
                break
            }
        }
        
        return encoded
    }
    
    
    //MARK: - Private - Mime Type
    
    private func mimeType(forPathExtension pathExtension: String) -> String {
        if
            let id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue(),
            let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue() {
            return contentType as String
        }
        
        return "application/octet-stream"
    }

    
    //MARK: - Private - Writing Body Part to Output Stream
    
    private func write(_ formPart: FormPart, to outputStream: OutputStream) throws {
        try writeInitialBoundaryData(for: formPart, to: outputStream)
        try writeHeaderData(for: formPart, to: outputStream)
        try writeBodyStream(for: formPart, to: outputStream)
        try writeFinalBoundaryData(for: formPart, to: outputStream)
    }
    
    private func writeInitialBoundaryData(for formPart: FormPart, to outputStream: OutputStream) throws {
        let initialData = formPart.isInitialBoundary ? self.initialBoundary : self.encapsulatedBoundary
        return try write(initialData, to: outputStream)
    }
    
    private func writeHeaderData(for formPart: FormPart, to outputStream: OutputStream) throws {
        let headerData = encodeHeaders(for: formPart)
        return try write(headerData, to: outputStream)
    }
    
    private func writeBodyStream(for formPart: FormPart, to outputStream: OutputStream) throws {
        let inputStream = formPart.inputStream
        
        inputStream.open()
        defer { inputStream.close() }
        
        while inputStream.hasBytesAvailable {
            var buffer = [UInt8](repeating: 0, count: self.streamBufferSize)
            let bytesRead = inputStream.read(&buffer, maxLength: self.streamBufferSize)
            
            if let streamError = inputStream.streamError {
                throw HellfireError.multipartEncodingFailed(reason: .inputStreamReadFailed(error: streamError))
            }
            
            if bytesRead > 0 {
                if buffer.count != bytesRead {
                    buffer = Array(buffer[0..<bytesRead])
                }
                
                try write(&buffer, to: outputStream)
            } else {
                break
            }
        }
    }
    
    private func writeFinalBoundaryData(for formPart: FormPart, to outputStream: OutputStream) throws {
        if formPart.isFinalBoundary {
            return try write(self.finalBoundary, to: outputStream)
        }
    }
    
    
    //MARK: - Private - Writing Buffered Data to Output Stream
    
    private func write(_ data: Data, to outputStream: OutputStream) throws {
        var buffer = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &buffer, count: data.count)
        
        return try write(&buffer, to: outputStream)
    }
    
    private func write(_ buffer: inout [UInt8], to outputStream: OutputStream) throws {
        var bytesToWrite = buffer.count
        
        while bytesToWrite > 0, outputStream.hasSpaceAvailable {
            let bytesWritten = outputStream.write(buffer, maxLength: bytesToWrite)
            
            if let error = outputStream.streamError {
                throw HellfireError.multipartEncodingFailed(reason: .outputStreamWriteFailed(error: error))
            }
            
            bytesToWrite -= bytesWritten
            
            if bytesToWrite > 0 {
                buffer = Array(buffer[bytesWritten..<buffer.count])
            }
        }
    }
    
    
    //MARK: - Private - Errors
    
    private func setBodyPartError(withReason reason: HellfireError.MultipartEncodingFailureReason) {
        guard self.formPartEncodingError == nil else { return }
        self.formPartEncodingError = HellfireError.multipartEncodingFailed(reason: reason)
    }
    
    
    //MARK: - Public API
    
    /// The boundary string used to separate the body components in a `multipart/formdata` request.
    public let boundary: String
    
    /// Gets the file manager used for file operations.  Injected in the init, will default to FileManager.default if not provided.
    public let fileManager: FileManager
    
    /// Returns the `Content Type` header as a `multipart/form-data` header including the boundry identifier used for the request body components.
    public lazy var contentType: HTTPHeader = HTTPHeader.contentType("multipart/form-data; boundary=\(self.boundary)")

    /// The content length of all body parts used to generate the `multipart/form-data` not including the boundaries.
    public var contentLength: UInt64 { formParts.reduce(0) { $0 + $1.contentLength } }
    
    /// Instantiates an instance of MultipartFormData, which is used to create the multipart form data request.
    /// - Parameters:
    ///   - boundary: The boundary `String` that separates multipart/formdata request body into the different parts.
    ///   - fileManager: The file manager used for file operations. Will default to FileManager.default if not provided.
    public init(boundary: String? = nil, fileManager: FileManager = FileManager.default) {
        self.boundary = boundary ?? "hellfire.boundary.\(String.randomString(length: 10))"
        self.initialBoundary = Data("--\(self.boundary)\(EncodingHelper.crlf)".utf8)
        self.fileManager = fileManager
        self.encapsulatedBoundary = Data("\(EncodingHelper.crlf)--\(self.boundary)\(EncodingHelper.crlf)".utf8)
        self.finalBoundary = Data("\(EncodingHelper.crlf)--\(self.boundary)--\(EncodingHelper.crlf)".utf8)
    }
    
    /// Encodes all appended body parts into a single `Data` value.
    ///
    /// - Note: This method will load all the appended body parts into memory all at the same time. This method should
    ///         only be used when the encoded data will have a small memory footprint. For large data cases, please use
    ///         the `writeEncodedData(to:))` method.
    ///
    /// - Returns: The encoded `Data`, if encoding is successful.
    /// - Throws:  An `HellfireError` if encoding encounters an error.
    public func encode() throws -> Data {
        if let formPartError = formPartEncodingError {
            throw formPartError
        }
        
        var encoded = Data()
        formParts.first?.isInitialBoundary = true
        formParts.last?.isFinalBoundary = true
        
        for formPart in formParts {
            let encodedData = try encode(formPart)
            encoded.append(encodedData)
        }
        
        return encoded
    }
    
    /// Writes all appended body parts to the given file `URL`.
    ///
    /// This process is facilitated by reading and writing with input and output streams, respectively. Thus,
    /// this approach is very memory efficient and should be used for large body part data.
    ///
    /// - Parameter fileURL: File `URL` to which to write the form data.
    /// - Throws:            An `HellfireError` if encoding encounters an error.
    public func writeEncodedData(to fileURL: URL) throws {
        if let formPartError = formPartEncodingError {
            throw formPartError
        }
        
        if fileManager.fileExists(atPath: fileURL.path) {
            throw HellfireError.multipartEncodingFailed(reason: .outputStreamFileAlreadyExists(at: fileURL))
        } else if !fileURL.isFileURL {
            throw HellfireError.multipartEncodingFailed(reason: .outputStreamURLInvalid(url: fileURL))
        }
        
        guard let outputStream = OutputStream(url: fileURL, append: false) else {
            throw HellfireError.multipartEncodingFailed(reason: .outputStreamCreationFailed(for: fileURL))
        }
        
        outputStream.open()
        defer { outputStream.close() }
        
        formParts.first?.isInitialBoundary = true
        formParts.last?.isFinalBoundary = true
        
        for formPart in formParts {
            try write(formPart, to: outputStream)
        }
    }
    
    
    //MARK: - Body Parts

    
    /// Creates a body part from the data and appends it to the instance.
    ///
    /// The body part data will be encoded using the following format:
    ///
    /// - `Content-Disposition: form-data; name=#{name}; filename=#{filename}` (HTTP Header)
    /// - `Content-Type: #{mimeType}` (HTTP Header)
    /// - Encoded file data
    /// - Multipart form boundary
    ///
    /// - Parameters:
    ///   - data:     `Data` to encoding into the instance.
    ///   - name:     Name to associate with the `Data` in the `Content-Disposition` HTTP header.
    ///   - fileName: Filename to associate with the `Data` in the `Content-Disposition` HTTP header.
    ///   - mimeType: MIME type to associate with the data in the `Content-Type` HTTP header.
    public func append(_ data: Data, withName name: String, fileName: String? = nil, mimeType: String? = nil) {
        let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
        let stream = InputStream(data: data)
        let length = UInt64(data.count)
        
        append(stream, withLength: length, headers: headers)
    }
    
    /// Creates a body part from the file and appends it to the instance.
    ///
    /// The body part data will be encoded using the following format:
    ///
    /// - `Content-Disposition: form-data; name=#{name}; filename=#{generated filename}` (HTTP Header)
    /// - `Content-Type: #{generated mimeType}` (HTTP Header)
    /// - Encoded file data
    /// - Multipart form boundary
    ///
    /// The filename in the `Content-Disposition` HTTP header is generated from the last path component of the
    /// `fileURL`. The `Content-Type` HTTP header MIME type is generated by mapping the `fileURL` extension to the
    /// system associated MIME type.
    ///
    /// - Parameters:
    ///   - fileURL: `URL` of the file whose content will be encoded into the instance.
    ///   - name:    Name to associate with the file content in the `Content-Disposition` HTTP header.
    public func append(_ fileURL: URL, withName name: String) {
        let fileName = fileURL.lastPathComponent
        let pathExtension = fileURL.pathExtension
        
        if !fileName.isEmpty && !pathExtension.isEmpty {
            let mime = mimeType(forPathExtension: pathExtension)
            append(fileURL, withName: name, fileName: fileName, mimeType: mime)
        } else {
            setBodyPartError(withReason: .bodyPartFilenameInvalid(in: fileURL))
        }
    }
    
    /// Creates a body part from the file and appends it to the instance.
    ///
    /// The body part data will be encoded using the following format:
    ///
    /// - Content-Disposition: form-data; name=#{name}; filename=#{filename} (HTTP Header)
    /// - Content-Type: #{mimeType} (HTTP Header)
    /// - Encoded file data
    /// - Multipart form boundary
    ///
    /// - Parameters:
    ///   - fileURL:  `URL` of the file whose content will be encoded into the instance.
    ///   - name:     Name to associate with the file content in the `Content-Disposition` HTTP header.
    ///   - fileName: Filename to associate with the file content in the `Content-Disposition` HTTP header.
    ///   - mimeType: MIME type to associate with the file content in the `Content-Type` HTTP header.
    public func append(_ fileURL: URL, withName name: String, fileName: String, mimeType: String) {
        let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
        
        //============================================================
        //                 Check 1 - is file URL?
        //============================================================
        
        guard fileURL.isFileURL else {
            self.setBodyPartError(withReason: .bodyPartURLInvalid(url: fileURL))
            return
        }
        
        //============================================================
        //              Check 2 - is file URL reachable?
        //============================================================
        
        do {
            let isReachable = try fileURL.checkPromisedItemIsReachable()
            guard isReachable else {
                self.setBodyPartError(withReason: .bodyPartFileNotReachable(at: fileURL))
                return
            }
        } catch {
            self.setBodyPartError(withReason: .bodyPartFileNotReachableWithError(atURL: fileURL, error: error))
            return
        }
        
        //============================================================
        //            Check 3 - is file URL a directory?
        //============================================================
        
        var isDirectory: ObjCBool = false
        let path = fileURL.path
        
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) && !isDirectory.boolValue else {
            self.setBodyPartError(withReason: .bodyPartFileIsDirectory(at: fileURL))
            return
        }
        
        //============================================================
        //          Check 4 - can the file size be extracted?
        //============================================================
        
        let bodyContentLength: UInt64
        
        do {
            guard let fileSize = try fileManager.attributesOfItem(atPath: path)[.size] as? NSNumber else {
                self.setBodyPartError(withReason: .bodyPartFileSizeNotAvailable(at: fileURL))
                return
            }
            
            bodyContentLength = fileSize.uint64Value
        } catch {
            self.setBodyPartError(withReason: .bodyPartFileSizeQueryFailedWithError(forURL: fileURL, error: error))
            return
        }
        
        //============================================================
        //       Check 5 - can a stream be created from file URL?
        //============================================================
        
        guard let stream = InputStream(url: fileURL) else {
            self.setBodyPartError(withReason: .bodyPartInputStreamCreationFailed(for: fileURL))
            return
        }
        
        self.append(stream, withLength: bodyContentLength, headers: headers)
    }
    
    /// Creates a body part from the stream and appends it to the instance.
    ///
    /// The body part data will be encoded using the following format:
    ///
    /// - `Content-Disposition: form-data; name=#{name}; filename=#{filename}` (HTTP Header)
    /// - `Content-Type: #{mimeType}` (HTTP Header)
    /// - Encoded stream data
    /// - Multipart form boundary
    ///
    /// - Parameters:
    ///   - stream:   `InputStream` to encode into the instance.
    ///   - length:   Length, in bytes, of the stream.
    ///   - name:     Name to associate with the stream content in the `Content-Disposition` HTTP header.
    ///   - fileName: Filename to associate with the stream content in the `Content-Disposition` HTTP header.
    ///   - mimeType: MIME type to associate with the stream content in the `Content-Type` HTTP header.
    public func append(_ stream: InputStream,
                       withLength length: UInt64,
                       name: String,
                       fileName: String,
                       mimeType: String) {
        let headers = contentHeaders(withName: name, fileName: fileName, mimeType: mimeType)
        append(stream, withLength: length, headers: headers)
    }
    
    /// Creates a body part with the stream, length, and headers and appends it to the instance.
    ///
    /// The body part data will be encoded using the following format:
    ///
    /// - HTTP headers
    /// - Encoded stream data
    /// - Multipart form boundary
    ///
    /// - Parameters:
    ///   - stream:  `InputStream` to encode into the instance.
    ///   - length:  Length, in bytes, of the stream.
    ///   - headers: `HTTPHeaders` for the body part.
    public func append(_ stream: InputStream, withLength length: UInt64, headers: Set<HTTPHeader>) {
        let formPart = FormPart(headers: headers, bodyStream: stream, bodyContentLength: length)
        self.formParts.append(formPart)
    }
}
