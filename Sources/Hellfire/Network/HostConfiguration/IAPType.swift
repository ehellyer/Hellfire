//
//  IAPType.swift
//  HellFire
//
//  Created by Ed Hellyer on 5/26/25.
//  Copyright © 2025 Ed Hellyer. All rights reserved.
//

import Foundation

/// Represents common Internet Application Protocols used for communication over a network.
/// Each case corresponds to a protocol identified by its standard URI scheme.
public enum IAPType: String, JSONSerializable {
    
    /// HyperText Transfer Protocol
    case http = "http"
    
    /// HyperText Transfer Protocol (Secure)
    case https = "https"
    
    /// File Transfer Protocol
    case ftp = "ftp"
    
    /// File Transfer Protocol Secure (FTP over SSL/TLS)
    case ftps = "ftps"
    
    /// SSH File Transfer Protocol
    case sftp = "sftp"
    
    /// Simple Mail Transfer Protocol
    case smtp = "smtp"
    
    /// Internet Message Access Protocol
    case imap = "imap"
    
    /// Post Office Protocol version 3
    case pop3 = "pop3"
    
    /// Domain Name System
    case dns = "dns"
    
    /// WebSocket Protocol
    case ws = "ws"
    
    /// WebSocket Protocol Secure
    case wss = "wss"
    
    /// Message Queuing Telemetry Transport
    case mqtt = "mqtt"
    
    /// Simple Object Access Protocol
    case soap = "soap"
    
    /// gRPC Remote Procedure Call Protocol
    case grpc = "grpc"
    
    /// Network Time Protocol
    case ntp = "ntp"
    
    /// Secure Shell Protocol
    case ssh = "ssh"
    
    /// Other (This option allows the developer to use an alternate IAPType that is not part of this list.  Can be done in code or by find/replace "IAPOther" in a URL string.)
    case other = "IAPOther"
}
