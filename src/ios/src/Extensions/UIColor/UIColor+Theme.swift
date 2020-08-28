extension UIColor{
    struct Theme {
        static var black: UIColor {
            if #available(iOS 13, *) {
                return UIColor.init { (trait) -> UIColor in
                    return trait.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
                }
            }
            return UIColor.black
        }

        static var white: UIColor {
            if #available(iOS 13, *) {
                return UIColor.init { (trait) -> UIColor in
                    return trait.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
                }
            }
            return UIColor.white
        }
    }
}
