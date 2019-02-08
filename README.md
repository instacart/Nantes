Nantes 🥕
========
[![CI Status](https://img.shields.io/travis/instacart/Nantes.svg?style=flat)](https://travis-ci.org/Instacart/Nantes)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/Nantes.svg)](https://img.shields.io/cocoapods/v/Nantes.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

This library is a Swift port/fork of the popular Objective-C library [TTTAttributedLabel](https://github.com/TTTAttributedLabel/TTTAttributedLabel). Much ❤️  and credit goes to [Mattt](https://github.com/mattt) for creating such a great UILabel replacement library.

`Nantes` is a pure-Swift `UILabel` replacement. It supports attributes, data detectors, and more. It also supports link embedding automatically and with `NSTextCheckingTypes`.

### Requirements ###
- iOS 8.0+
- Swift 4.2

### Installation ###

Nantes is available through [Carthage](https://github.com/Carthage/Carthage). To install
it, add the following line to your `Cartfile`:
```
github "instacart/nantes"
```

### Cocoapods

Nantes is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Nantes'
```

### Communication

If you need help, feel free to open an issue. Please search before opening one, someone might have run into something similar.

### Contributing

Opening a pull request is the best way to get something fixed. If you need help, feel free to open an issue, hopefully someone can help you out with a problem you're running into.

### Author

chansen22, chris.hansen@instacart.com

### Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

### Getting Started ###

Check out `Nantes` in the `Example` directory for more examples.

```swift
import Nantes

let label: NantesLabel = .init(frame: .zero)
label.attributedTruncationToken = NSAttributedString(string: "... more")
label.numberOfLines = 3
label.labelTappedBlock = {
  label.numberOfLines = label.numberOfLines == 0 ? 3 : 0 // Flip between limiting lines and not

  UIView.animateWithDuration(0.2, animations: {
    self.view.layoutIfNeeded()
  })
}

label.text = "Nantes label is great! Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus ac urna et ante lobortis varius. Nunc rhoncus enim vitae sem commodo sodales. Morbi id augue id augue finibus tincidunt. Cras ac massa nisi. Maecenas elementum vitae elit eu mattis. Duis pretium turpis ut justo accumsan molestie. Mauris elit elit, maximus eu risus sed, vestibulum sodales enim. Sed porttitor vestibulum tincidunt. Maecenas mollis tortor quam, sed porta justo rhoncus id. Phasellus vitae augue tempor, luctus metus sit amet, dictum urna. Morbi sit amet feugiat purus. Proin vitae finibus lectus, eu gravida erat."
view.addSubview(label)

let linkLabel: NantesLabel = .init(frame: .zero)
linkLabel.delegate = self // NantesLabelDelegate
linkLabel.linkAttributes = [NSAttributedString.Key.foregroundColor: UIColor.green]
linkLabel.text = "https://www.instacart.com"
view.addSubview(linkLabel)

// Link handling

func attributedLabel(_ label: NantesLabel, didSelectLink link: URL) {
  print("Tapped link: \(link)")
}


```

## License

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

