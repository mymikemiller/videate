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

    public func stringifyError(msg: Text): Text {
        stringifyDocument(createErrorDocument(msg));
    };

    func createErrorDocument(msg: Text): Document = {
        prolog = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
        root = {
            name = "Error";
            attributes = [];
            text = msg;
            children = [];
        };
    };

    public func stringifyElement(element: Element, indentationLevel: Nat): Text {
        // Remove characters not supported in xml
        func sanitize(str: Text) : Text { Text.replace(str, #text("&"), "&amp;") };

        // todo: remove Option.make when the member is changed back to optional
        let attributes = Option.get(Option.make(element.attributes), []);
        let text = Option.get(Option.make(sanitize(element.text)), "");
        let children = Option.get(Option.make(element.children), []);
        
        let arr = Array.tabulate<Text>(indentationLevel, func _ { "  " });
        let indent = Array.foldLeft(arr, "", Text.concat);

        func foldAttributes(accum: Text, attribute: (Text, Text)): Text {
            accum # " " # attribute.0 # "=\"" # sanitize(attribute.1) # "\"";
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
