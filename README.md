# profile.d

A dotfiles management system for Bash. It symlinks your dotfiles into place, runs your shell customizations through a
five-stage hook lifecycle, and installs each piece of it as a plugin you list in one config file.

## Install

```bash
curl https://raw.githubusercontent.com/jakubro/profile.d/main/bin/install | bash
\. ~/.bashrc
```

Then list the plugins you want in `~/.profiledrc` and re-run `profile.d-install`.

## Documentation

**[jakubro.github.io/profile.d](https://jakubro.github.io/profile.d/)** - installation, configuration, the hook
lifecycle, the available plugins, and how to write your own.

## Contributing

If you would like to contribute to this project, please feel free to submit a pull request or open an issue for
discussion.

## License

MIT License - see the [LICENSE](LICENSE) file for details.
