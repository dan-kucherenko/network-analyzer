//
//  File.swift
//  network-analizer
//
//  Created by Daniil on 11.03.2025.
//

import Foundation

let config = URLSessionConfiguration.default
//config.httpAdditionalHeaders = ["User-Agent": "MyApp"]
config.httpShouldSetCookies = true
config.httpCookieAcceptPolicy = .always
config.httpShouldUsePipelining = true
