import Array "mo:base/Array";

module {
    public type Node = {
        #element: { name: Text; attributes: [(Text, Text)]; children: [Node]};
        #text: Text;
    };

    public type Document = { 
        prolog: Text;
        root: Node; 
    };

    public func stringifyDocument(document: Document): Text {
        return document.prolog # "\n" # stringifyNode(document.root);
    };

    public func stringifyNode(node: Node): Text {
        func foldAttributes(accum: Text, attribute: (Text, Text)): Text {
            accum # " " # attribute.0 # "=\"" # attribute.1 # "\"";
        };
        func foldChildren(accum: Text, child: Node): Text {
            accum # stringifyNode(child);
        };
        return switch (node) {
            case (#text(t)) { t };
            case (#element{name; attributes; children}) {
                return "\n<" # name
                    # Array.foldLeft<(Text, Text), Text>(attributes, "", foldAttributes) # ">"
                    # Array.foldLeft<Node, Text>(children, "", foldChildren)
                    # "</" # name # ">";
            };
        };
    };
}
