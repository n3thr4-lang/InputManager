local Signal = require(script.Parent.Signal)

export type InputKey = Enum.KeyCode | "mouse_wheel_up" | "mouse_wheel_down" | Enum.UserInputType

export type Action = {
	Active: boolean,
	UserData: any?,

	Name: string,
	Manager: Manager,

	Triggered: Signal.Signal
		<
		"began" | "ended",
	boolean,
	InputKey?,
	Vector3?,
	string?,
	{string}?
		>,

	Disabled: Signal.Signal<>,
	Activated: Signal.Signal<>,
	KeyAdded: Signal.Signal<InputKey>,
	KeyRemoved: Signal.Signal<InputKey>,

	Activate: (self: Action) -> (),
	Disable: (self: Action) -> (),

	AddKey: (self: Action, key: InputKey | InputObject) -> (),
	RemoveKey: (self: Action, key: InputKey | InputObject) -> (),

	HasKey: (self: Action, key: InputKey) -> (boolean),
	GetKey: (self: Action) -> ({InputKey})?,

	Destroy: (self: Action) -> ()
}

export type Context = {
	UserData: any?,
	GlobalFallback: boolean,

	Fallback: {string},

	Name: string,
	Manager: Manager,

	KeyChanged: Signal.Signal<{[InputKey]: string}>,

	GlobalFallbackEnabled: Signal.Signal<>,
	GlobalFallbackDisabled: Signal.Signal<>,

	OnFallback: Signal.Signal<InputKey, boolean, string?>,
	FallbackChanged: Signal.Signal<{string}>,

	EnableGlobalFallback: (self: Context) -> (),
	DisableGlobalFallback: (self: Context) -> (),

	GetKey: (self: Context) -> ({[InputKey]: string}),
	HasKey: (self: Context, key: InputKey) -> (boolean),
	SetFallback: (self: Context, fallbackList: {string}) -> (),
	SetKey: (self: Context, keyList: {[InputKey]: string}) -> (),
	Destroy: (self: Context) -> ()
}


export type Manager = {
	CurrentContext: string?,
	Active: boolean,

	ActionToKey: {[string]: {[InputKey]: boolean}},
	KeyToAction: {[InputKey]: string},
	ContextKey: {[string]: {[InputKey]: string}},

	ActionList: {[string]: Action},
	ContextList: {[string]: Context},
	UserData: any?,
	Blacklist: {[InputKey]: boolean},

	Connection: {[string]: RBXScriptConnection},

	ActionAdded: Signal.Signal<string>,
	ActionRemoved: Signal.Signal<string, any?>,

	ContextAdded: Signal.Signal<string>,
	ContextRemoved: Signal.Signal<string, any?>,
	CurrentContextChanged: Signal.Signal<string?, string?>,

	BlacklistChanged: Signal.Signal<{InputKey}>,
	BlacklistKeyStopped: Signal.Signal<InputKey, string, "action" | "context">,
	Activated: Signal.Signal<>,
	Disabled: Signal.Signal<>,

	ActionTriggered: Signal.Signal
		<
		string,
	Action,
	"began" | "ended",
	boolean,
	InputKey?,
	Vector3?,
	string?,
	{string}?
		>,

	AddAction: (
		self: Manager,
		actionName: string,
		actionConfig: ActionConfig?
	) -> (Action),

	AddContext: (
		self: Manager,
		contextName: string,
		contextConfig: ContextConfig?
	) -> (Context),

	SetBlacklist: (
		self: Manager,
		blacklistKey: {InputKey}
	) -> (),

	TriggerKey: (
		self: Manager,
		key: InputKey | InputObject,
		state: "began" | "ended",
		gameProcessed: boolean?,
		inputPosition: Vector3?
	) -> (),

	TriggerAction: (
		self: Manager,
		actionName: string,
		state: "began" | "ended",
		gameProcessed: boolean?,
		inputPosition: Vector3?
	) -> (),

	GetAction: (self: Manager, actionName: string) -> (Action), -- keep without "?" for autocomplete
	GetContext: (self: Manager, contextName: string) -> (Context), -- same here

	Destroy: (self: Manager) -> (),

	ResolveAction: (
		self: Manager,
		object: InputKey | InputObject
	) -> (string?, Action?, string?, {string}?),

	SetContext: (self: Manager, context: string?) -> (),

	Activate: (self: Manager) -> (),
	Disable: (self: Manager) -> (),
}

export type ManagerConfig = {
	UserData: any?,
	Blacklist: {InputKey}?
}

export type ActionConfig = {
	UserData: any?,
	Active: boolean?
}

export type ContextConfig = {
	GlobalFallback: boolean?,
	Fallback: {string}?,
	UserData: any?
}

export type InputManager = {
	new: (config: ManagerConfig?) -> (Manager)
}

return {}