import Foundation

/// Public deployment identifiers, never AWS credentials or client secrets.
public struct CognitoConfiguration {
  public let clientID: String
  public let loginURL: URL

  public init(clientID: String, loginURL: String) throws {
    guard !clientID.isEmpty, clientID.count <= 128,
      clientID.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.contains($0) && $0.isASCII })
    else {
      throw RelayError.invalid(
        "Cloud sign-in is not configured. Set RELAY_COGNITO_CLIENT_ID for your deployment.")
    }
    self.clientID = clientID
    self.loginURL = try CloudCodec.apiURL(loginURL)
    guard self.loginURL.path.isEmpty || self.loginURL.path == "/" else {
      throw RelayError.invalid("Use the HTTPS origin of your Cognito login domain, without a path.")
    }
  }

  public static func load(
    info: [String: Any] = Bundle.main.infoDictionary ?? [:],
    environment: [String: String] = ProcessInfo.processInfo.environment
  ) throws -> Self {
    try Self(
      clientID: environment["RELAY_COGNITO_CLIENT_ID"] ?? info["RELAYCognitoClientID"] as? String
        ?? "",
      loginURL: environment["RELAY_COGNITO_LOGIN_URL"] ?? info["RELAYCognitoLoginURL"] as? String
        ?? ""
    )
  }
}
