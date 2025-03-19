# ScreenManager

A dynamic script to manage multiple display configurations in i3wm with support for rotation, resolution, and custom layouts.

## Features

- **Multiple Display Management**: Extend, mirror, or show individual displays with a simple interface
- **Rotation Support**: Rotate displays in different orientations (normal, left, right, inverted)
- **Resolution Control**: Select from available resolutions for each connected display
- **Custom Layouts**: Create custom arrangements with flexible positioning (right-of, left-of, above, below)
- **i3wm Integration**: Automatically restarts i3 after display changes for seamless transitions


## Installation

1. Clone this repository or download the script:

```bash
git clone https://github.com/hdprajwal/ScreenManager.git
```

2. Make the script executable:

```bash
chmod +x screenmanager.sh
```

## Dependencies

- `xrandr`: For display management
- `rofi`: For the menu interface
- `i3-msg`: For i3wm integration

Install dependencies on Debian/Ubuntu:

```bash
sudo apt install rofi
```

## Usage

Simply run the script:

```bash
./screenmanager.sh
```

### i3 Integration

For seamless integration with i3, add this to your i3 config file:

```
# Display management
bindsym $mod+Shift+p exec --no-startup-id screenmanager
```

## Logging

All actions are logged to `~/.local/share/screenmanager/screenmanager.log`. Check this file for debugging:

```bash
cat ~/.local/share/screenmanager/screenmanager.log
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feat/<feature-name>`)
3. Commit your changes (`git commit -m '<commit-message>'`)
4. Push to the branch (`git push origin feat/<feature-name>`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

- **Prajwal HD** - [hdprajwal](https://github.com/hdprajwal)