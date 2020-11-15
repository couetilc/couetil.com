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

function initLoginForm() {
    document.querySelector('#login').addEventListener('submit', async (e) => {
        e.preventDefault();
        const uid = e.target.elements.uid.value;
        const pwd = e.target.elements.pwd.value;
        try {
            const login = await auth.login(uid, pwd)
            console.log({ login })
            document.querySelector("#username").innerText = login.uid;
            popup().hide();
        } catch (error) {
            alert(error)
        }
    })
}

function initSignupForm() {
    document.querySelector('#signup').addEventListener('submit', async (e) => {
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

function initLoginButton() {
    document.querySelector('#btn-login').addEventListener('click', (e) => {
        popup().show();
    })
}

function popup() {
    const get = () => document.querySelector('#popup')

    const methods = {
        init: () => {
            document.querySelector('#popup-close').addEventListener('click', () => {
                methods.hide();
            })
        },
        show: () => {
            get().style.display = 'flex';
        },
        hide: () => {
            get().style.display = 'none';
        }
    }

    return methods
}

function App() {
    mitt.on('load', initLoginForm)
    mitt.on('load', initSignupForm)
    mitt.on('load', initLoginButton)
    mitt.on('load', popup().init)

    return {
        init: (e) => {
            window.addEventListener('load', (e) => mitt.emit('load', e))
        }
    }
}

const app = App()
app.init();