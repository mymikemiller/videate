import m from 'mithril'

const User = {
    list: [],
    loadList: function () {
        return m.request({
            method: 'GET',
            url: "https://rem-rest-api.herokuapp.com/api/users",
            withCredentials: true,
        }).then(function (result) {
            User.list = result.data
        })
    },
    current: {},
    load: function (id) {
        return m.request({
            method: "GET",
            url: "https://rem-rest-api.herokuapp.com/api/users/" + id,
            withCredentials: true,
        })
            .then(function (result) {
                User.current = result
            })
    },
    save: function () {
        console.log(User.current);
        return m.request({
            method: "PUT",
            url: "https://rem-rest-api.herokuapp.com/api/users/" + User.current.id,
            body: User.current,
            withCredentials: true,
        })
    }
}

export default User
