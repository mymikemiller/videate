import m from "mithril"

export default {
    view: function (vnode) {
        return m("main.layout", [
            m("nav.menu", [
                m(m.route.Link, { href: "/list" }, "Users")
            ]),
            m("section", vnode.children)
        ])
    }
}
