module {
    public type Request = {
        method: Text;
        headers: [([Nat8], [Nat8])];
        uri: Text;
        body: [Nat8];
    };

    public type Response = {
        status: Nat16;
        headers: [([Nat8], [Nat8])];
        body: [Nat8];
        upgrade: Bool;
    };
}
