window.addEventListener('load', () => {
    document.querySelector('#login').addEventListener('submit', async (e) => {
        e.preventDefault();
        // login
        const uid = e.target.elements.uid.value;
        const pwd = e.target.elements.pwd.value;
        const response = await fetch('http://localhost:3000/auth/password', {
            method: 'POST',
            body: JSON.stringify({ uid, pwd })
        })
        const login = await response.json()
        console.log({ login })
        // error
        if (login.error) {
            alert(login.error)
        }
        else {
            // success
            document.querySelector("#username").innerText = login.uid;
        }
    })
    document.querySelector('#signup').addEventListener('submit', async (e) => {
        e.preventDefault();
        // login
        const uid = e.target.elements.uid.value;
        const pwd = e.target.elements.pwd.value;
        const response = await fetch('http://localhost:3000/auth/signup', {
            method: 'POST',
            body: JSON.stringify({ uid, pwd })
        })
        const signup = await response.json();
        console.log({ signup })
        // error
        if (signup.error) {
            alert(signup.error)
        }
        else {
            // success
            document.querySelector("#signup-message").innerText = "Hello " + signup.uid + "!";
        }
    })
})