import { DB } from "https://deno.land/x/sqlite@v2.3.1/mod.ts"
import { parse } from "https://deno.land/std@0.76.0/flags/mod.ts"
import { Application, RouterContext, Router } from "https://deno.land/x/oak@v6.3.1/mod.ts"
import { hash, verify, genSalt } from "https://deno.land/x/scrypt@v2.0.0/mod.ts"
import { Status } from "https://deno.land/std@0.76.0/http/mod.ts"
import { debug } from "https://deno.land/std@0.76.0/log/mod.ts"
import { DateTimeFormatter } from "https://deno.land/std@0.76.0/datetime/formatter.ts"
import { CHAR_QUESTION_MARK } from "https://deno.land/std@0.73.0/path/_constants.ts"

/**
 * REST API
 * Users Resource
 *     GET /users/ (get all users, return UserCollection, maybe optionally accept a ids query parameter which can be array)
 *     POST /users/ (create a user)
 *     GET /users/:id (get user object for user id)
 *     PUT /users/:id (replace user object for user id, return new user)
 *     PATCH /users/:id (modify user properties for user id, return modified user)
 *     DELETE /users/:id (delete a user, and returns the User object for the deleted user (or maybe don't return anything))
 *     GET /users/:id/sessions/ (get all sessions as summary objects for a user)
 *     GET /users/:id/sessions/:id (get session summary object for id, return link to user info and link to session info)
 *     NOTES
 *      - public users could be id = 0, but they all have individual sessions which are tracked.
 *        (public users with id = 0 would be part of NoAccount)
 * Sessions Resource
 *     GET /sessions/ (get all sessions)
 *     POST /sessions/ (create a new session, return a session id)
 *     GET /sessions/:id (get session object for session id)
 *     DELETE /sessions/:id (delete a session)
 * Credentials Resource? (would list all the means a user has for authentication: username/password, phone number + 1 time pass, SAML, FaceID, etc.)
 *     GET /users/:id/credentials (get all the credential methods for a user?)
 *     NOTES
 *      - a form of credential could be IP and browser fingerprint, for example. We could then
 *        create this user, attach a session, and voila, someone can access the whole website and
 *        have a user without having to log in.
 *      - could set permission level based on what credential method a user used to log in
 *        (users that are IP or plogin based could have basic functionality, but to update profile information
 *         would require authentication using username/password credential or OTP credential, and to change
 *         password would require MFA)
 * Authenticate Resource? (would initiate the login flow for the particular login type)
 *     GET /auth/login (username/password form)
 *     POST /auth/login (username/password return session token or something? is auth token distinct from session token? Basic auth integration here?)
 *     POST /auth/otp (one-time password, with query parameter: device=phone|email)
 *     POST /auth/mfa (username/password and one-time password, with query parameter: device=phone|email)
 * Accounts (Each user is associated with an account, including the special account "NoAccount", id=0,  for public users)
 *     GET /accounts/ (list all accounts)
 *     POST /accounts/ (create an account)
 *     PUT /accounts/:id (replace account information)
 *     PATCH /accounts/:id (modify account information)
 *     DELETE /accounts/:id (delete account information)
 *     GET /accounts/:id/users (list all users under an account)
 *     GET /accounts/:id/users/:id (get user summary object? or just return the same thing as /users/:id?)
 * Permissions/Roles/Scopes? (these are permissions associated with a user)
 *     GET /perms/ (return all permission information)
 *     GET /perms/:id (return permission information)
 *     GET /users/:id/perms (return all permissions for a user)
 *     GET /users/:id/perms (return same  thing as /perms/:id? or return summary object? could have optional "expand" parameter)
 * Groups (Each user can be part of a group, with the default being the special group "NoGroup")
 *     NOTES
 *      - it might be better if each account has separate groups, which then contain users.
 *      - an account is a collection of its groups. Its groups are collections of its users.
 *      - what does it mean to have an across account group? what does it mean to have a user in multiple groups?
 *        (Basically, what's the benefit of groups at all?)
 *  NOTES
 *  - Login As Feature: (how the hell would this work, and also what would it look like as REST API and DB Schema?)
 *  - what if a user account is used by multiple people? Like a Netflix login shared by a Family?
 *  - most users could be one account with one user each, but many will be a family with one account but multiple users.
 *    those family members could be organized into different groups, each with different permissions.
 *  - if a user is member of the "NoAccount" account (e.g. public user), then they cannot be associated with any
 *    other accounts. if a user is member of the "NoGroup" group, then they cannot be associated with any groups.
 *    How do we handle different user personas? Are they just each different users under the same account?
 *  TODO
 *  - can a user put in any password? Chinese characters etc.? Look up "Unicode normalization"
 *      - case-insensitive comparison can create an issue with non-ASCII characters, someone logging in
 *        from one locale may be unable to log in from a different locale, due to differences in how
 *        each locale lowercases characters in their password.
 *  - cap password length at a reasonable limit.
 *  - SCIM
 *  - when DELETE /users/:id, first inactivate, then delete all data after a time period like 3months (see if GDPR has guidelines).
 *  SOME RESOURCES
 *  - nice reference https://www.vinaysahni.com/best-practices-for-a-pragmatic-restful-api
 *  - tips for rolling auth https://news.ycombinator.com/item?id=18767767
 *  NOMENCLATURE
 *  - "uid" the string a user is unique identified by at login. NOT the id given to the user object in the database
 *  - "pwd" the string a user has as a password for logging in. NOT the pass stored as a hash in the database
 *  - "pass" salted hash of the user's password
 *  DEPLOYMENT
 *  - couetil.com has to be a progressive web app
 *  - deploy couetil.com usin gk3s https://github.com/rancher/k3s/
 */

 /** CLI Arguments/Ideas
  *  CURRENT
  *     "db" - sqlite database name
  *     "port" - server port number
  *  TODO
  *     "--soft-delete" if true only soft delete users, otherwise do a hard delete
  */

/**
 * Get a cryptographically secure random salt as a hexadecimal string. Salts
 * should be about the same number of bytes as the final hash. 64-bit salts
 * should have a no collision for about a billion tries (TODO the math here)
 * @returns nbyte hexadecimal string (two char per byte)
 */
export function getSalt(nbytes: number): string {
    if (nbytes < 0) throw new Error('number of bytes can\'t be negative');
    let salt = '';
    const salty = crypto.getRandomValues(new Uint8Array(nbytes));
    for (const rand of salty) {
      salt += rand.toString(16).padStart(2, '0');
    }
    return salt;
}

/**
 * Return a string formatted timestamp for a date, defaultting to current
 * TODO have it return a pretty formatted UTC string instead of epoch time
 */
function timestamp(date: Date = new Date()) {
    return date.getTime();
}

// TODO implement login with QR code

interface AuthDatabase {
    client: DB,
}

interface AuthError {
    error: string,
    status: Status,
}

interface UserModel {
    insert: (cred: Credential) => Promise<User>,
    selectAll: () => UserCollection,
    select: (id: number) => User,
    update: (id: number, user: NewUser) => Promise<User>,
    delete: (id: number) => void,
}

// TODO add "pwd: string" here
interface NewUser {
    uid: string,
}

interface User {
    uid: string,
    id: number,
    created: string,
    edited: string,
}

interface UserCollection {
    users: Array<User>,
    count: number,
}

interface Credential {
    uid: string,
    pwd: string,
}

function auth_database(name: string): AuthDatabase {
    // init
    const client = new DB(name);
    client.query(`create table if not exists users (
      id integer primary key autoincrement,
      uid text not null unique,
      salt text not null,
      pass text not null,
      created text default current_timestamp,
      edited text default current_timestamp
    )`);
    // interface
    return { client };
}

function user_model(db: AuthDatabase): UserModel {
    // TODO pull cryptography stuff out of the user model? bloats it unnecessarily,
    // could just be a function that accepts a NewUser and returns a DBUsers which
    // is then passed to the function.
    const model: UserModel = {
        insert: async ({ uid, pwd }) => {
            const salt = getSalt(64); // 64 because the hashed password is 64 bytes (hexadecimal string length 128)
            const pass = await hash(salt + pwd);
            // TODO error handling by catching sql errors and translating it to custom errors?
            db.client.query(
                "insert into users (uid, salt, pass) values (:uid, :salt, :pass)",
                // TODO perform UTF case folding, which allow for a case-insensitive comparison. Not enough to normalize UTF string
                // TODO create a case folding library (port this over https://github.com/seanmonstar/unicase)
                { uid: uid.normalize('NFKC'), salt, pass }
            );
            const userRow = db.client.query(
                "select * from users where rowid = last_insert_rowid()"
            )
            const user = [ ...userRow.asObjects() ][0];
            console.log({ fn: 'user_model', method: 'insert', message: 'created user', user, timestamp: timestamp() })
            return {
                id: user.id,
                uid: user.uid,
                created: user.created,
                edited: user.edited,
            }
        },
        selectAll: () => {
            const rows = db.client.query(`select * from users`);
            const users = [ ...rows.asObjects() ]
            return {
                users: users.map(user => ({
                    id: user.id,
                    uid: user.uid,
                    created: user.created,
                    edited: user.edited,
                })),
                count: users.length,
            };
        },
        select: (id) => {
            const rows = db.client.query(`select * from users where id = :id`, { id });
            const user = [ ...rows.asObjects() ][0];
            // TODO get rid of this throws, instead should return an error object/interface
            if (!user) {
                // e.g. would return { error: 'no user', status: Status.NotFound }}
                throw new Error('no user');
            }
            return {
                id: user.id,
                uid: user.uid,
                created: user.created,
                edited: user.edited,
            };
        },
        update: async (id, user) => {
            const current_user: User = model.select(id)
            // TODO get rid of this throws, instead should return an error object/interface
            if (!current_user) {
                // e.g. would return { error: 'no user', status: Status.NotFound }}
                throw new Error('no user')
            }
            // TODO what happens if update password?
            const updated_user = { ...current_user, ...user }
            db.client.query(`update users set uid = :uid where id = :id`, { id, uid: updated_user.uid })
            return model.select(id)
        },
        delete: async (id) => {
            db.client.query(`delete from users where id = :id`, { id });
        }
    }

    return model;
}

function auth_router(db: AuthDatabase): Router {
    return new Router()
        .get('/ping', (ctx) => {
            ctx.response.body = 'pong';
        })
        .get('/args', (ctx) => {
            ctx.response.body = { ...args }
        })
        .get('/users', (ctx) => {
            ctx.response.body = user_model(db).selectAll();
        })
        .post('/users', async (ctx: RouterContext) => {
            /* validation */

            // parse body
            ctx.assert(ctx.request.hasBody, Status.BadRequest, 'missing request body')
            // required body format
            let uid, pwd;
            try {
                ({ uid, pwd } = await ctx.request.body({ type: 'json' }).value);
            } catch (error) {
                ctx.assert(false, Status.BadRequest, 'request body must be JSON');
            }
            // required parameters
            ctx.assert(uid && pwd, Status.BadRequest, 'request body requires username and password')

            /* functionality */

            // create user
            try {
                const user = await user_model(db).insert({ uid, pwd })
                ctx.response.body = user
            } catch (error) {
                // TODO I wonder where database error handling code should go? The user model? The controller?
                console.log({ error });
                // Sqlite Constraint Error - user exists already
                ctx.response.status = Status.InternalServerError
                ctx.response.body = { error: 'error creating user' }
                // TODO only add error object to response if debug/logging level is development
            }
        })
        .get('/users/:id', async (ctx: RouterContext) => {
            /* validation */

            const user_id = Number(ctx.params?.id);
            // required parameter
            ctx.assert(user_id, Status.BadRequest, 'must specify user id')

            /* functionality */

            try {
                const user = user_model(db).select(user_id);
                ctx.response.body = user;
            } catch (error) {
                ctx.response.status = Status.NotFound;
            }
        })
        .put('/users/:id', async (ctx: RouterContext) => {
            // what about password? can they update password? any special permissions?
            // maybe requires an authentication level? For now I will not allow changing password

            /* validation */

            const user_id = Number(ctx.params?.id)
            ctx.assert(user_id, Status.BadRequest, 'must specify user id')

            // parse body
            ctx.assert(ctx.request.hasBody, Status.BadRequest, 'missing request body')
            // required body format
            let uid;
            try {
                ({ uid } = await ctx.request.body({ type: 'json' }).value);
            } catch (error) {
                ctx.assert(false, Status.BadRequest, 'request body must be JSON');
            }
            // required parameters
            ctx.assert(uid, Status.BadRequest, 'request body requires username and password')

            /* functionality */

            try {
                const updated_user = await user_model(db).update(user_id, { uid });
                ctx.response.body = updated_user
            } catch (error) {
                // TODO if no user, then 404
                // otherwise, 500
                ctx.response.status = Status.InternalServerError
            }
        })
        .patch('/users/:id', async (ctx: RouterContext) => {
            /* validation */

            const user_id = Number(ctx.params?.id)
            ctx.assert(user_id, Status.BadRequest, 'invalid input')
            ctx.assert(ctx.request.hasBody, Status.BadRequest, 'invalid input')

            let uid;
            try {
                ({ uid } = await ctx.request.body({ type: 'json' }).value);
            } catch (error) {
                ctx.assert(false, Status.BadRequest, 'invalid input');
            }
            ctx.assert(uid, Status.BadRequest, 'invalid input')

            /* functionality */

            try {
                const updated_user = await user_model(db).update(user_id, { uid });
                ctx.response.body = updated_user
            } catch (error) {
                // TODO if no user, then 404
                // otherwise, 500
                ctx.response.status = Status.InternalServerError
            }
        })
        .delete('/users/:id', async (ctx: RouterContext) => {
            // hard delete for now, maybe soft delete in the future. Also could be a CLI flag

            /* validation */

            const user_id = Number(ctx.params?.id)
            ctx.assert(user_id, Status.BadRequest, 'must specify user id')

            /* functionality */

            try {
                user_model(db).delete(user_id);
                ctx.response.status = Status.OK
            } catch (error) {
                console.log({ error })
                // TODO if no user, then 404
                // otherwise, 500
                ctx.response.status = Status.InternalServerError
            }
        })
}

function auth_application(db: AuthDatabase) {
    const router = auth_router(db);
    const oak = new Application();
    oak.use(router.routes());
    oak.use(router.allowedMethods());
    oak.addEventListener('listen', (e) => {
      console.log('event %o at %o', e.type, `${e.secure ? 'https' : 'http'}://${e.hostname || 'localhost'}:${e.port}`);
    })
    return oak;
}

async function server (db_name = 'auth.db', port = 3000) {
    const db = auth_database(db_name);
    const oak = auth_application(db);
    await oak.listen({ port })
}

// parse cli args
const args = parse(Deno.args);
const dbname = args.db;
const port = args.port || 3000;

// run server
await server (dbname, port);
