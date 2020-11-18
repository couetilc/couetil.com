function SDK() {
    const base_url = 'http://localhost:3000'
    return {
        login: async (uid, pwd) => {
            const response = await fetch(`${base_url}/auth/password`, {
                method: 'POST',
                body: JSON.stringify({ uid, pwd })
            })
            const login = await response.json()
            if (login.error) {
                throw new Error(login.error)
            }
            document.cookie = `token=${login.uid};`
            return login;
        },
        signup: async (uid, pwd) => {
            const response = await fetch(`${base_url}/auth/signup`, {
                method: 'POST',
                body: JSON.stringify({ uid, pwd })
            })
            const signup = await response.json();
            if (signup.error) {
                throw new Error(signup.error)
            }
            return signup;
        },
        logout: () => {
            document.cookie = `token=;`;
        }
    }
}

function m () {
    let chs = {}
    return {
        emit: (channel, message) => {
            if (!chs[channel]) {
                return
            }
            chs[channel].forEach(fn => fn(message));
        },
        on: (channel, handler) => {
            if (!chs[channel]) {
                chs[channel] = []
            }
            chs[channel].push(handler);
        },
    }
}

// const mitt = window.mitt();
const mitt = m();
const auth = SDK();

function login_form() {
    const get = () => document.querySelector('#login')
    login_form.init = () => {
        get().addEventListener('submit', async (e) => {
            e.preventDefault();
            const uid = e.target.elements.uid.value;
            const pwd = e.target.elements.pwd.value;
            try {
                const login = await auth.login(uid, pwd)
                console.log({ login })
                username().set(login.uid)
                popup().hide();
            } catch (error) {
                alert(error)
            }
        })
    }
    return login_form;
}

function signup_form() {
    const get = () => document.querySelector('#signup')
    signup_form.init = () => {
        get().addEventListener('submit', async (e) => {
            e.preventDefault();
            const uid = e.target.elements.uid.value;
            const pwd = e.target.elements.pwd.value;
            try {
                const signup = await auth.signup(uid, pwd);
                console.log({ signup })
                document.querySelector("#signup-message").innerText = "Hello " + signup.uid + "!";
            }
            catch (error) {
                alert(error)
            }
        })
    }
    return signup_form
}

function login_button() {
    const get = () => document.querySelector('#btn-login')
    login_button.init = () => {
        get().addEventListener('click', (e) => {
            popup().show()
        })
    }
    return login_button
}

function logout_button() {
    const get = () => document.querySelector('#btn-logout')
    logout_button.init = () => {
        get().addEventListener('click', (e) => {
            username().set('')
            auth.logout()
        })
    }
    return logout_button
}

function popup() {
    const get = () => document.querySelector('#popup')

    popup.init = () => {
        document.querySelector('#popup-close').addEventListener('click', () => {
            methods.hide()
        })
    },
    popup.show = () => {
        get().style.display = 'flex'
    },
    popup.hide = () => {
        get().style.display = 'none'
    }

    return popup
}

function username() {
    const get = () => document.querySelector('#username')
    username.set = (val) => {
        document.querySelector("#username").innerText = val
    }
    return username
}

function App() {
    mitt.on('load', login_form().init)
    mitt.on('load', signup_form().init)
    mitt.on('load', login_button().init)
    mitt.on('load', logout_button().init)
    mitt.on('load', popup().init)

    return {
        init: (e) => {
            window.addEventListener('load', (e) => mitt.emit('load', e))
        }
    }
}

const app = App()
app.init()