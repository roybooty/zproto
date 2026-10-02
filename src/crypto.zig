const std = @import("std");
const zPortoKey = std.crypto.dh.X25519;
const zProtoSymmetric = std.crypto.kdf.hkdf.HkdfSha256;
const chachapoly = std.crypto.aead.chacha_poly.ChaCha20Poly1305;
const zProtoErrors = std.crypto.errors;

//const Nonce = struct {
//   pub counter: u64 = 0,

//    pub fn next(self: *Nonce) [chachapoly.nonce_length]u8 {
//        var buffer_nonce = [_]u8{0} ** chachapoly.nonce_length;
//        std.mem.writeInt(u64, buffer_nonce[0..8], self.counter, .little);
//        self.counter += 1;
//        return buffer_nonce;
//    }
//};

pub fn generateKey(io: std.Io) zPortoKey.KeyPair {
    return zPortoKey.KeyPair.generate(io);
}

pub fn getSharedKsymetric(secret_key: [zPortoKey.secret_length]u8, public_key: [zPortoKey.public_length]u8) ![32]u8 {
    const ourK = try zPortoKey.scalarmult(secret_key, public_key);
    const fake = [_]u8{0} ** 32;
    return zProtoSymmetric.extract(&fake, &ourK);
}

// testing
pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const ServerKeys: zPortoKey.KeyPair = generateKey(io);
    const ClientKeys: zPortoKey.KeyPair = generateKey(io);

    const ServerSymetricKey = try getSharedKsymetric(ServerKeys.secret_key, ClientKeys.public_key);
    const ClientSymetricKey = try getSharedKsymetric(ClientKeys.secret_key, ServerKeys.public_key);


    std.debug.print("{x}\n", .{ServerSymetricKey});
    std.debug.print("{x}\n", .{ClientSymetricKey});

}
