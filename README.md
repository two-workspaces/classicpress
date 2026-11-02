# Deploy and Host ClassicPress on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/classicpress-cms?referralCode=sLjDXb&utm_medium=integration&utm_source=button&utm_campaign=classicpress-cms)

[ClassicPress](https://www.classicpress.net/) is a community fork of WordPress for people who want a CMS without the block editor: the classic editor, a smaller codebase, and PHP 8 support. Most WordPress plugins and themes that don't depend on blocks work unchanged. This template runs it on the official image with a private MariaDB and no open installer.

## About Hosting ClassicPress

The stack is two services: ClassicPress (Apache and PHP 8.3) and a private MariaDB.

- **Installed before it goes public.** A fresh install shows its setup page to whoever opens the URL first, and bots scan new domains for exactly that. This template installs ClassicPress on the first boot with the login `admin` and a generated password. MariaDB has a generated password and no public proxy. The security keys and salts are random, written once and kept on the volume, so logins survive redeploys.
- **Limits for real sites.** 128 MB uploads (the stock image stops at 2 MB), 256 MB of PHP memory and 5-minute requests for imports and big plugin installs. Apache is sized to your plan's memory, and pretty permalinks are on.
- **Updates as usual.** After the first install, ClassicPress updates itself from the dashboard. Its files, themes, plugins and uploads live on the volume.

## Common Use Cases

- A blog, portfolio or company site without the block editor
- A home for a WordPress site whose editors prefer the classic editor
- Client sites that should stay simple and light for years

## Dependencies for ClassicPress Hosting

- MariaDB 11.8 LTS (included, private network only)

### Deployment Dependencies

- [ClassicPress documentation](https://docs.classicpress.net/)
- [ClassicPress plugin directory](https://directory.classicpress.net/)
- [Template source on GitHub](https://github.com/two-workspaces/classicpress)

### Implementation Details

**Sign in** at `https://<your domain>/wp-admin` with the username `admin` and the `CP_ADMIN_PASSWORD` value from the ClassicPress service's Variables tab. Afterwards, change the password (Users → Profile) and the admin email (Settings → General). Both variables are read on the first boot only.

**Email.** ClassicPress sends password resets and notifications by email, and the container has no mail server. Railway allows outbound SMTP only on the Pro plan. On any plan, install a mail plugin that sends through an email provider's HTTPS API. Until you set one up, ClassicPress can't send email. If you lose the admin password, set a new one from a `railway ssh` session on the ClassicPress service: `wp --allow-root user update admin --user_pass='new-password' --path=/var/www/html`.

**Custom domain.** After adding one on Railway, change both addresses in Settings → General to it.

## Why Deploy ClassicPress on Railway?

Railway runs the site and its database together, with private networking between them, TLS on the public domain, and a volume for each. You skip the installer race and the upload limits, and you pay for what the site uses.
