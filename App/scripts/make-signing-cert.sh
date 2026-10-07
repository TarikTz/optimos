#!/bin/bash
# Creates a self-signed code-signing certificate named "OptimosApp Local Signing" in your login
# keychain (once; safe to re-run). Signing every build with the same certificate gives the app a
# stable identity, so macOS keeps the Screen Recording permission across rebuilds and updates.
# It is not an Apple certificate: it does not remove the first-run Gatekeeper warning.
set -euo pipefail
NAME="OptimosApp Local Signing"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"

if security find-certificate -c "$NAME" "$KEYCHAIN" > /dev/null 2>&1; then
  echo "Certificate '$NAME' already exists."
  security find-certificate -c "$NAME" -Z "$KEYCHAIN" | grep "SHA-1"
  exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/openssl.cnf" <<CNF
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = $NAME
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
CNF
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -config "$TMP/openssl.cnf" \
  -keyout "$TMP/key.pem" -out "$TMP/cert.pem" 2> /dev/null
PASS=$(uuidgen)
/usr/bin/openssl pkcs12 -export -inkey "$TMP/key.pem" -in "$TMP/cert.pem" -name "$NAME" \
  -out "$TMP/id.p12" -passout "pass:$PASS"
security import "$TMP/id.p12" -k "$KEYCHAIN" -P "$PASS" -T /usr/bin/codesign > /dev/null
# Trust it for code signing (macOS asks for your password or Touch ID once).
security add-trusted-cert -r trustRoot -p codeSign -k "$KEYCHAIN" "$TMP/cert.pem"
echo "Created '$NAME'."
security find-certificate -c "$NAME" -Z "$KEYCHAIN" | grep "SHA-1"
