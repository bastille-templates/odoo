## Now apply template to container

```sh
bastille create itop 14.1-RELEASE YourIP-Bastille
bastille bootstrap https://github.com/bastille-templates/itop
bastille template itop bastille-templates/itop --args PHP_V=82
```

- Apache to PHP-FPM Socket

## License

This project is licensed under the BSD-3-Clause license.
