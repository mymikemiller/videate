import m from "mithril";

import UserList from "./views/UserList";
import UserForm from "./views/UserForm";
import Layout from "./views/Layout";
import "./styles.css";

import credits from 'ic:canisters/credits';

m.route(document.body, '/list', {
    '/list': {
        render: () => m(Layout, m(UserList))
    },
    '/edit/:id': {
        render: (vnode) => m(Layout, m(UserForm, vnode.attrs))
    },
})
