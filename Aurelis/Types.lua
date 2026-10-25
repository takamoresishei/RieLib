--!strict
-- Public option and handle contracts for consumers using strict Luau.
export type ThemeName = "Eclipse" | "Obsidian" | "Graphite" | "Tokyo" | "OLED" | "Frost" | "Light"
export type MotionPreset = "Instant" | "Fast" | "Normal" | "Slow" | "Spring"
export type KeybindMode = "Toggle" | "Hold" | "Always"
export type WindowOptions = {
    Title: string?,
    Subtitle: string?,
    Size: UDim2?,
    MinimumSize: Vector2?,
    Parent: Instance?,
    Acrylic: boolean?,
    Blur: boolean?,
    Theme: ThemeName?,
    ToggleKey: Enum.KeyCode?,
    StatusBar: boolean?,
}
export type ComponentOptions = {
    Title: string?,
    Description: string?,
    Icon: string?,
    Tooltip: string?,
    Flag: string?,
    ConfigPriority: number?,
    Disabled: boolean?,
    Visible: boolean?,
}
export type ValueComponent<T> = {
    GetValue: (self: ValueComponent<T>) -> T,
    SetValue: (self: ValueComponent<T>, value: T, silent: boolean?) -> (boolean, string?),
    SetDisabled: (self: ValueComponent<T>, disabled: boolean) -> ValueComponent<T>,
    SetVisible: (self: ValueComponent<T>, visible: boolean) -> ValueComponent<T>,
    Reset: (self: ValueComponent<T>) -> (boolean, string?),
    Destroy: (self: ValueComponent<T>) -> (),
}
export type SliderOptions = ComponentOptions & {
    Min: number?,
    Max: number?,
    Default: number?,
    Increment: number?,
    Suffix: string?,
    Callback: ((number) -> ())?,
}
export type ToggleOptions = ComponentOptions & { Default: boolean?, Callback: ((boolean) -> ())? }
export type DropdownOptions = ComponentOptions & {
    Values: { string },
    Multi: boolean?,
    Default: (string | { string })?,
    Callback: ((string | { string }) -> ())?,
}
export type InputOptions = ComponentOptions & {
    Type: ("Text" | "Number" | "Password")?,
    Default: (string | number)?,
    Placeholder: string?,
    CharacterLimit: number?,
    SubmitOnEnter: boolean?,
    Live: boolean?,
    Min: number?,
    Max: number?,
    Validate: ((string | number) -> (boolean, string?))?,
}
export type KeybindValue = { Key: Enum.KeyCode, Mode: KeybindMode }
export type State<T> = {
    Get: (self: State<T>) -> T,
    Set: (self: State<T>, value: T) -> (),
    Destroy: (self: State<T>) -> (),
}
export type ConfigReport = { Applied: { string }, Skipped: { string } }
export type ConfigAdapter = {
    Read: (name: string) -> string,
    Write: (name: string, data: string) -> (),
    Delete: (name: string) -> (),
    List: () -> { string },
}
return {}
