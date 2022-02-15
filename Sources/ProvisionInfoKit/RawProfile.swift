import Foundation
import Security

public struct RawProfile {
    public var fields: [String: Any]
}

extension RawProfile {
    public init(data: Data) throws {
        let decoded = try decodeProfile(data: data)
        self.init(fields: decoded)
    }
}

func decodeProfile(data: Data) throws -> [String: Any] {
    var decoder: CMSDecoder?
    var status: OSStatus = errSecSuccess

    status = CMSDecoderCreate(&decoder)
    guard status == errSecSuccess, let decoder = decoder else {
        throw ProvisionInfoError.cmsDecoderCreationFailure(status)
    }

    status = data.withUnsafeBytes { ptr in
        CMSDecoderUpdateMessage(decoder, ptr.baseAddress!, data.count)
    }
    guard status == errSecSuccess else {
        throw ProvisionInfoError.cmsDecoderUpdateFailure(status)
    }

    status = CMSDecoderFinalizeMessage(decoder)
    guard status == errSecSuccess else {
        throw ProvisionInfoError.cmsDecoderFinalizeFailure(status)
    }

    var decodedCFData: CFData?
    status = CMSDecoderCopyContent(decoder, &decodedCFData)
    guard status == errSecSuccess, let decodedCFData = decodedCFData else {
        throw ProvisionInfoError.cmsDecoderCopyFailure(status)
    }

    let decodedData = decodedCFData as Data
    guard let dict = try PropertyListSerialization.propertyList(
        from: decodedData, options: [], format: nil
    ) as? [String: Any] else {
        throw ProvisionInfoError.profileDeserializationFailure
    }

    return dict
}
