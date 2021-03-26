import Array "mo:base/Array";
import Option "mo:base/Option";
import Text "mo:base/Text";

module {
    public type Element = {
        name: Text;
        attributes: [(Text, Text)];
        text: Text;
        children: [Element];
    };

    public type Document = { 
        prolog: Text;
        root: Element; 
    };

    public func stringifyDocument(document: Document): Text {
        document.prolog # stringifyElement(document.root, 0);
    };

    public func stringifyElement(element: Element, indentationLevel: Nat): Text {
        // Remove characters not supported in xml
        let sanitizedText = Text.replace(element.text, #text("&"), "&amp;");

        // todo: remove Option.make when the member is changed back to optional
        let attributes = Option.get(Option.make(element.attributes), []);
        let text = Option.get(Option.make(sanitizedText), "");
        let children = Option.get(Option.make(element.children), []);
        
        let arr = Array.tabulate<Text>(indentationLevel, func _ { "  " });
        let indent = Array.foldLeft(arr, "", Text.concat);

        func foldAttributes(accum: Text, attribute: (Text, Text)): Text {
            accum # " " # attribute.0 # "=\"" # attribute.1 # "\"";
        };
        func foldChildren(accum: Text, child: Element): Text {
            accum # stringifyElement(child, indentationLevel + 1);
        };

        let newlineAndIndentIfChildren = 
            if (element.children.size() > 0) { "\n" # indent } 
            else { "" };

        return "\n" # indent # "<" # element.name
            # Array.foldLeft<(Text, Text), Text>(attributes, "", foldAttributes) # ">"
            # text
            # Array.foldLeft<Element, Text>(children, "", foldChildren)
            # newlineAndIndentIfChildren
            # "</" # element.name # ">";
    };
}
