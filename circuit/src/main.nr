// Prove knowledge of two u32 values that sum to a public result.
// u32 inputs trigger range-check lookup tables, generating the BSB22
// commitment needed by the on-chain Groth16+BSB22 verifier.
fn main(a: u32, b: u32) -> pub Field {
    (a + b) as Field
}
