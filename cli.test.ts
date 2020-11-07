import { assertEquals } from "https://deno.land/std@0.76.0/testing/asserts.ts";


Deno.test(makeTest({
    name: 'cli',
    ignore: true,
    args: { port: 3001, db: ":memory:" },
    fn: async () => {
        // test if returns the cli arguments the server was started with
        const res = await fetch('http://localhost:3001/args');
        assertEquals(await res.json(), { _: [], port: 3001, db: ':memory:' });
    },
}));

Deno.test(makeTest({
    name: 'subprocess',
    ignore: true,
    args: { port: 3000, db: ":memory:" },
    fn: async () => {
        // test if responds to ping with a pong
        const res = await fetch('http://localhost:3000/ping');
        assertEquals(await res.text(), "pong");
    },
}));

Deno.test(makeTest({
    name: 'users',
    args: { port: 3001, db: ":memory:" },
    fn: async () => {
        let response, user;
        // test if returns list of empty users when db is not initialized
        response = await fetch('http://localhost:3001/users');
        assertEquals(await response.json(), { users: [], count: 0 });

        // test if error when POST has no body
        response = await fetch('http://localhost:3001/users', { method: 'POST' });
        assertEquals(response.status, 400);
        assertEquals(await response.text(), 'missing request body');

        // test if error when POST has no username
        response = await fetch('http://localhost:3001/users', {
            method: 'POST',
            body: JSON.stringify({ uid: 'foo' })
        });
        assertEquals(response.status, 400);
        assertEquals(await response.text(), 'request body requires username and password');

        // test if error when POST has no password
        response = await fetch('http://localhost:3001/users', {
            method: 'POST',
            body: JSON.stringify({ pwd: 'foo' })
        });
        assertEquals(response.status, 400);
        assertEquals(await response.text(), 'request body requires username and password');

        // test if error when POST has empty username and password
        response = await fetch('http://localhost:3001/users', {
            method: 'POST',
            body: JSON.stringify({ uid: '', pwd: '' })
        });
        assertEquals(response.status, 400);
        assertEquals(await response.text(), 'request body requires username and password');

        // test if error when POST body is not JSON
        response = await fetch('http://localhost:3001/users', {
            method: 'POST',
            body:  `uid=connor&pwd=candy`
        });
        assertEquals(response.status, 400);
        assertEquals(await response.text(), 'request body must be JSON');

        // test for creating a new user
        response = await fetch('http://localhost:3001/users', {
            method: 'POST',
            body: JSON.stringify({
                uid: 'connor',
                pwd: 'icecream'
            }),
        });
        user = await response.json();
        assertEquals(user.id, 1);
        assertEquals(user.uid, 'connor');
        assertEquals(typeof user.created, 'string')
        assertEquals(typeof user.edited, 'string')
        assertEquals(typeof user.pwd, 'undefined')
        assertEquals(typeof user.pass, 'undefined')
        assertEquals(typeof user.salt, 'undefined')

        // test for failing to creating a new user because they exist already
        response = await fetch('http://localhost:3001/users', {
            method: 'POST',
            body: JSON.stringify({
                uid: 'connor',
                pwd: 'cake'
            }),
        });
        assertEquals(response.status, 500)
        assertEquals(await response.json(), { error: 'error creating user' });

        // test for validating a GET /users/:id request
        response = await fetch('http://localhost:3001/users/abc')
        assertEquals(response.status, 400);
        assertEquals(await response.text(), 'must specify user id')

        // test for GET-ing a non-existent user by id
        response = await fetch('http://localhost:3001/users/2')
        assertEquals(response.status, 404);
        response.body?.cancel() // clear httpBody resource

        // test for GET-ing a user by id
        response = await fetch('http://localhost:3001/users/1')
        user = await response.json();
        assertEquals(response.status, 200);
        assertEquals(user.uid, 'connor')
        assertEquals(user.id, 1)
        assertEquals(typeof user.created, 'string')
        assertEquals(typeof user.edited, 'string')

        // test for PUT-ing a user by id
        response = await fetch('http://localhost:3001/users/1', {
            method: 'PUT',
            body: JSON.stringify({
                uid: 'jade',
            })
        })
        assertEquals(response.status, 200);
        response.body?.cancel() // clear httpBody resource
        response = await fetch('http://localhost:3001/users/1')
        user = await response.json();
        assertEquals(response.status, 200);
        assertEquals(user.uid, 'jade')
        assertEquals(user.id, 1)
        assertEquals(typeof user.created, 'string')
        assertEquals(typeof user.edited, 'string')

        // TODO test for PATCH-ing a user by id
        response = await fetch('http://localhost:3001/users/1', {
            method: 'PATCH',
            body: JSON.stringify({
                uid: 'cooper',
            })
        })
        assertEquals(response.status, 200);
        response.body?.cancel() // clear httpBody resource
        response = await fetch('http://localhost:3001/users/1')
        user = await response.json();
        assertEquals(response.status, 200);
        assertEquals(user.uid, 'cooper')
        assertEquals(user.id, 1)
        assertEquals(typeof user.created, 'string')
        assertEquals(typeof user.edited, 'string')


        // TODO test for DELETE-ing a user
        response = await fetch('http://localhost:3001/users/1', {
            method: 'DELETE',
        })
        assertEquals(response.status, 200);
        response.body?.cancel() // clear httpBody resource
        response = await fetch('http://localhost:3001/users/1')
        response.body?.cancel() // clear httpBody resource
        assertEquals(response.status, 404);

        // // test for failing to creating a new user beause the uid exists (ASCII case-insensitive comparison)
        // response = await fetch('http://localhost:3001/users', {
        //     method: 'POST',
        //     body: JSON.stringify({
        //         uid: 'CoNnOr',
        //         pwd: 'pie'
        //     }),
        // });
        // assertEquals(await response.json(), { error: 'error creating user' });

        // test for unicode normalization and case-folding (UTF case-insensitive comparison)
        // response = await fetch('http://localhost:3001/users', {
        //     method: 'POST',
        //     body: JSON.stringify({
        //         uid: 'Maße',
        //         pwd: 'pie'
        //     }),
        // });
        // const user2 = await response.json();
        // assertEquals(user2.id, 1);
        // assertEquals(user2.uid, 'Maße');
        // assertEquals(typeof user2.created, 'string')
        // assertEquals(typeof user2.edited, 'string')
        // assertEquals(typeof user2.pwd, 'undefined')
        // assertEquals(typeof user2.pass, 'undefined')
        // assertEquals(typeof user2.salt, 'undefined')
        // response = await fetch('http://localhost:3001/users', {
        //     method: 'POST',
        //     body: JSON.stringify({
        //         uid: 'MASSE',
        //         pwd: 'pie'
        //     }),
        // });
        // assertEquals(await response.json(), { error: 'error creating user' });
        // response = await fetch('http://localhost:3001/users', {
        //     method: 'DELETE',
        //     body: JSON.stringify({
        //         uid: 'Maße',
        //         pwd: 'pie'
        //     }),
        // });
        // response = await fetch('http://localhost:3001/users', {
        //     method: 'POST',
        //     body: JSON.stringify({
        //         uid: 'MASSE',
        //         pwd: 'pie'
        //     }),
        // });
        // const user3 = await response.json();
        // assertEquals(user3.id, 1);
        // assertEquals(user3.uid, 'MASSE');
        // assertEquals(typeof user3.created, 'string')
        // assertEquals(typeof user3.edited, 'string')
        // assertEquals(typeof user3.pwd, 'undefined')
        // assertEquals(typeof user3.pass, 'undefined')
        // assertEquals(typeof user3.salt, 'undefined')
    },
}));

interface CLIArgs {
    port?: number,
    db?: string,
}

async function setup(args: CLIArgs = {}): Promise<Deno.Process> {
    const { port, db = ':memory:' } = args;
    const cmd = ["deno", "run", ];
    const perm = ["--allow-net", "--allow-run", "--allow-write", "--allow-read"];
    // map args object to cli options
    const arg = Object.entries(args).reduce((arr: Array<string>, entry: [string, any]): Array<string> => {
        const [key, val] = entry;
        if (val) {
            return [ ...arr, `--${key}`, val ]
        }
        console.log('%o', { val, key })
        return arr
    }, [] as Array<string>)
    // start server
    const server_process = Deno.run({
        cmd: [ ...cmd, ...perm, "cli.ts", ...arg, ],
        // stdout: 'piped',
        // stderr: 'piped'
    });
    // wait until server is ready
    await poll(`http://localhost:${port}/ping`, 100)
    return server_process;
}

async function teardown(process: Deno.Process): Promise<void> {
    process.close();
}

async function poll(url: string, interval: number = 1000, timeout: number = 30000) {
    // resolves when server is responding to requests, rejects if server does not respond within a time period
    return new Promise((resolve, reject) => {
        let tid: number, iid: number;
        // poll server until it responds
        iid = setInterval(async () => {
            try {
                const response = await fetch(url);
                await response.body?.cancel(); // closes httpBody resource handle
                if (!response.ok) {
                    throw new Error(`response NOT ok`);
                }
                clearInterval(iid);
                clearTimeout(tid);
                resolve();
            } catch (ignored) {
            }
        }, interval);
        // throw error if the server hasn't responded within a timeout period
        tid = setTimeout(() => {
            clearInterval(iid);
            reject();
        }, timeout)
    });
}

interface TestArgs extends Deno.TestDefinition {
    args?: CLIArgs
}

function makeTest(definition: TestArgs) {
    const { args, fn, ...options } = definition;
    let process: Deno.Process;
    return {
        ...options,
        fn: async () => {
            try {
                process = await setup(args);
                await fn();
            } catch (carried) {
                throw carried;
            } finally {
                await teardown(process);
            }
        },
    };
}
