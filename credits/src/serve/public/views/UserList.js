import m from 'mithril'
import User from '../models/User'

const UserList = {
    oninit: User.loadList,
    view: function () {
        return m('.user-list', User.list.map(function (user) {
            return m(m.route.Link, {
                class: 'user-list-item',
                href: '/edit/' + user.id,
            }, user.firstName + ' ' + user.lastName)
        }))
    }
}

export default UserList

