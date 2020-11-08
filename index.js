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

const auth = SDK();

window.addEventListener('load', () => {
    document.querySelector('#login').addEventListener('submit', async (e) => {
        e.preventDefault();
        const uid = e.target.elements.uid.value;
        const pwd = e.target.elements.pwd.value;
        try {
            const login = await auth.login(uid, pwd)
            console.log({ login })
            document.querySelector("#username").innerText = login.uid;
        } catch (error) {
            alert(error)
        }
    })
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
})