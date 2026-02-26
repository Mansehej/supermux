import {
  ASCIIFontRenderable,
  BoxRenderable,
  InputRenderable,
  InputRenderableEvents,
  RGBA,
  SelectRenderable,
  SelectRenderableEvents,
  TextRenderable,
  createCliRenderer,
} from "@opentui/core"

type Item = {
  label: string
  session: string
  kind: string
  win: string
  logical: string
}

const args = Bun.argv.slice(2)

const arg = (flag: string) => {
  const index = args.indexOf(flag)
  if (index === -1) return undefined
  return args[index + 1]
}

const mode = arg("--mode") ?? "pick"
const dataFile = arg("--data-file")
const resultFile = arg("--result-file")
const query = (arg("--query") ?? "").toLowerCase().trim()

const termProgram = process.env.TERM_PROGRAM ?? ""
const colorMode = (process.env.TMX_COLOR_MODE ?? (termProgram === "Apple_Terminal" ? "ansi" : "truecolor")).toLowerCase()
const useShadedBackgrounds = colorMode !== "ansi"

const normalizeSessionName = (value: string) =>
  value
    .replace(/[\t\r\n]+/g, " ")
    .replace(/\s+/g, " ")
    .trim()

if (!dataFile) throw new Error("missing --data-file")
if (!resultFile) throw new Error("missing --result-file")

const raw = await Bun.file(dataFile).text()

const allItems = raw
  .split(/\r?\n/)
  .filter((line) => line.length > 0)
  .map((line) => {
    const part = line.split("\t")
    return {
      label: part[0] ?? "",
      session: part[1] ?? "",
      kind: part[3] ?? "S",
      win: part[4] ?? "-",
      logical: part[5] ?? "",
    } satisfies Item
  })

const items = query
  ? allItems.filter((item) => item.label.toLowerCase().includes(query))
  : allItems

const renderer = await createCliRenderer({
  exitOnCtrlC: false,
})

const panelBase = RGBA.fromHex("#111821")
const panelRaised = RGBA.fromHex("#18222d")
const panelMuted = RGBA.fromHex("#8698af")
const panelText = RGBA.fromHex("#c8d4e4")
const accentPrimary = RGBA.fromHex("#ff8b7e")
const selectionShade = RGBA.fromHex("#223142")
const selectionShadeFocus = RGBA.fromHex("#2b3e52")

let index = 0
let done = false

const get = (i: number) => {
  if (!items.length) return undefined
  if (i < 0) return items[0]
  if (i >= items.length) return items[items.length - 1]
  return items[i]
}

const forSessionAction = (item: Item | undefined) => {
  if (!item) return undefined
  return {
    ...item,
    win: "-",
    kind: "S",
  }
}

const write = async (action: string, item?: Item) => {
  if (done) return
  done = true
  const session = item?.session ?? ""
  const win = item?.kind === "W" ? item.win : "-"
  await Bun.write(resultFile, `${action}\t${session}\t${win}\n`)
  renderer.destroy()
}

const root = new BoxRenderable(renderer, {
  width: "100%",
  height: "100%",
  justifyContent: "center",
  alignItems: "center",
})

renderer.root.add(root)

const frameProps: ConstructorParameters<typeof BoxRenderable>[1] = {
  width: "86%",
  height: "86%",
  minWidth: 56,
  minHeight: 16,
  flexDirection: "column",
  justifyContent: items.length ? "flex-start" : "center",
  alignItems: "center",
  paddingTop: 1,
  paddingBottom: 1,
  paddingLeft: 2,
  paddingRight: 2,
  gap: 1,
}
if (useShadedBackgrounds) {
  frameProps.backgroundColor = RGBA.fromHex("#0d1218")
}
const frame = new BoxRenderable(renderer, frameProps)

root.add(frame)

const hero = new BoxRenderable(renderer, {
  width: "100%",
  flexDirection: "column",
  justifyContent: "center",
  alignItems: "center",
  gap: 1,
})

frame.add(hero)

hero.add(
  new ASCIIFontRenderable(renderer, {
    text: "SUPERMUX",
    font: "tiny",
    color: RGBA.fromHex("#ff7f73"),
  }),
)

const helpText =
  mode === "kill"
    ? "Enter kill  Esc cancel"
    : mode === "detach"
      ? "Enter detach  Esc cancel"
      : "Enter attach  Ctrl-N new  Ctrl-D detach  Ctrl-X kill  Ctrl-R refresh  Esc cancel"

hero.add(
  new TextRenderable(renderer, {
    content: helpText,
    fg: panelMuted,
  }),
)

let select: SelectRenderable | undefined

if (items.length) {
  frame.add(
    new TextRenderable(renderer, {
      content: mode === "kill" ? "KILL" : mode === "detach" ? "DETACH" : "SESSIONS",
      fg: accentPrimary,
    }),
  )

  const listProps: ConstructorParameters<typeof BoxRenderable>[1] = {
    width: "100%",
    flexGrow: 1,
    paddingTop: 1,
    paddingBottom: 1,
    paddingLeft: 1,
    paddingRight: 1,
  }
  if (useShadedBackgrounds) {
    listProps.backgroundColor = panelBase
  }
  const list = new BoxRenderable(renderer, listProps)

  frame.add(list)

  select = new SelectRenderable(renderer, {
    width: "100%",
    height: "100%",
    selectedIndex: 0,
    options: items.map((item, i) => ({
      name: item.label,
      description: item.kind === "W" ? `${item.logical} window` : `${item.logical} session`,
      value: `${i}`,
    })),
  })

  if (useShadedBackgrounds) {
    select.backgroundColor = panelBase
  }
  select.textColor = panelText
  select.descriptionColor = panelMuted
  if (useShadedBackgrounds) {
    select.selectedBackgroundColor = selectionShade
    select.focusedBackgroundColor = selectionShadeFocus
  }
  select.selectedTextColor = accentPrimary
  select.selectedDescriptionColor = panelText

  list.add(select)
  select.focus()

  select.on(SelectRenderableEvents.SELECTION_CHANGED, (next: number) => {
    index = next
  })

  select.on(SelectRenderableEvents.ITEM_SELECTED, (next: number) => {
    index = next
    const item = get(index)
    if (mode === "kill") {
      void write("kill", forSessionAction(item))
      return
    }
    if (mode === "detach") {
      void write("detach", forSessionAction(item))
      return
    }
    void write("attach", item)
  })
} else {
  frame.add(
    new TextRenderable(renderer, {
      content:
        mode === "kill"
          ? "No sessions available to kill"
          : mode === "detach"
            ? "No attached sessions available"
            : "No sessions found for this scope",
      fg: panelMuted,
    }),
  )
}

const createEnabled = mode === "pick"
const createBoxProps: ConstructorParameters<typeof BoxRenderable>[1] = {
  width: "100%",
  flexDirection: "column",
  gap: 1,
  paddingTop: 1,
  paddingBottom: 1,
  paddingLeft: 2,
  paddingRight: 2,
}
if (useShadedBackgrounds) {
  createBoxProps.backgroundColor = panelRaised
}
const createBox = new BoxRenderable(renderer, createBoxProps)
const createTitle = new TextRenderable(renderer, {
  content: "NEW SESSION",
  fg: accentPrimary,
})
const createHint = new TextRenderable(renderer, {
  content: "Type a session name and press Enter",
  fg: panelMuted,
})
const createInput = new InputRenderable(renderer, {
  width: "100%",
  placeholder: "new-session",
  value: "",
})
createBox.add(createTitle)
createBox.add(createHint)
createBox.add(createInput)

let createOpen = false
const openCreate = () => {
  if (!createEnabled) return
  if (createOpen) return
  createOpen = true
  createHint.content = "Type a session name and press Enter"
  createInput.value = ""
  frame.add(createBox)
  createInput.focus()
}
const closeCreate = () => {
  if (!createOpen) return
  createOpen = false
  frame.remove(createBox)
  if (items.length) select?.focus()
}

createInput.on(InputRenderableEvents.CHANGE, () => {
  if (!createOpen) return
  if (createHint.content === "Type a session name and press Enter") return
  createHint.content = "Type a session name and press Enter"
})

createInput.on(InputRenderableEvents.ENTER, () => {
  if (!createOpen) return
  const name = normalizeSessionName(createInput.value)
  if (!name) {
    createHint.content = "Session name cannot be empty"
    return
  }
  void write("new", {
    label: name,
    session: name,
    kind: "S",
    win: "-",
    logical: name,
  })
})

if (createEnabled && !items.length) {
  openCreate()
}

renderer.keyInput.on("keypress", (key) => {
  if (key.ctrl && key.name === "c") {
    void write("cancel")
    return
  }

  if (key.name === "escape") {
    if (createOpen) {
      closeCreate()
      return
    }
    void write("cancel")
    return
  }

  if (createEnabled && key.ctrl && key.name === "n") {
    openCreate()
    return
  }

  if (createOpen) {
    return
  }

  if (!items.length) {
    if (createEnabled && (key.name === "enter" || key.name === "return")) {
      openCreate()
    }
    return
  }

  const item = get(index)

  if (mode === "pick") {
    if (key.ctrl && key.name === "d") {
      void write("detach", forSessionAction(item))
      return
    }
    if (key.ctrl && key.name === "x") {
      void write("kill", forSessionAction(item))
      return
    }
    if (key.ctrl && key.name === "r") {
      void write("refresh")
      return
    }
  }

  if (mode === "kill" && key.ctrl && key.name === "r") {
    void write("refresh")
    return
  }

  if (mode === "detach" && key.ctrl && key.name === "r") {
    void write("refresh")
  }
})
