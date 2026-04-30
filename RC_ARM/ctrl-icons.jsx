// Stroked geometric icons — thin-line, instrument style
const Icon = ({ size = 20, stroke = 'currentColor', strokeWidth = 1.5, children, style = {} }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
    stroke={stroke} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round"
    style={style}>
    {children}
  </svg>
);

const IconArrowUp = (p) => <Icon {...p}><path d="M12 19V5M6 11l6-6 6 6"/></Icon>;
const IconArrowDown = (p) => <Icon {...p}><path d="M12 5v14M6 13l6 6 6-6"/></Icon>;
const IconArrowLeft = (p) => <Icon {...p}><path d="M19 12H5M11 6l-6 6 6 6"/></Icon>;
const IconArrowRight = (p) => <Icon {...p}><path d="M5 12h14M13 6l6 6-6 6"/></Icon>;

const IconCar = (p) => (
  <Icon {...p}>
    <path d="M3 13l2-5a2 2 0 0 1 2-1.5h10a2 2 0 0 1 2 1.5l2 5v5h-2v-1H5v1H3v-5z"/>
    <circle cx="7" cy="16" r="1.5"/>
    <circle cx="17" cy="16" r="1.5"/>
    <path d="M3 13h18"/>
  </Icon>
);

const IconArm = (p) => (
  <Icon {...p}>
    <rect x="3" y="18" width="18" height="3" rx="0.5"/>
    <path d="M7 18v-4l5-3 3 3v2"/>
    <circle cx="7" cy="14" r="1.5"/>
    <circle cx="12" cy="11" r="1.5"/>
    <path d="M15 13l3-2M15 14l3-2"/>
  </Icon>
);

const IconHome = (p) => <Icon {...p}><path d="M3 12l9-8 9 8M5 10v10h14V10"/></Icon>;
const IconGrab = (p) => (
  <Icon {...p}>
    <path d="M8 4v6M12 3v8M16 4v6"/>
    <path d="M6 10c0 4 2 7 6 7s6-3 6-7"/>
    <path d="M10 17v4M14 17v4"/>
  </Icon>
);
const IconLift = (p) => <Icon {...p}><path d="M12 3v12M6 9l6-6 6 6M4 21h16"/></Icon>;
const IconRest = (p) => <Icon {...p}><path d="M4 18h16M6 18v-3M10 18v-5M14 18v-4M18 18v-2"/><circle cx="12" cy="6" r="2"/></Icon>;

const IconSend = (p) => <Icon {...p}><path d="M3 12l18-8-7 18-3-8-8-2z"/></Icon>;
const IconClose = (p) => <Icon {...p}><path d="M6 6l12 12M18 6l-12 12"/></Icon>;
const IconChevron = (p) => <Icon {...p}><path d="M9 6l6 6-6 6"/></Icon>;
const IconPower = (p) => <Icon {...p}><path d="M12 3v8"/><path d="M6.3 7.7a8 8 0 1 0 11.4 0"/></Icon>;
const IconBluetooth = (p) => <Icon {...p}><path d="M7 8l10 8-5 4V4l5 4-10 8"/></Icon>;
const IconSignal = (p) => <Icon {...p}><path d="M4 20h2v-4H4zM10 20h2v-8h-2zM16 20h2V8h-2z"/></Icon>;
const IconBattery = (p) => <Icon {...p}><rect x="2" y="7" width="18" height="10" rx="1.5"/><path d="M22 11v2"/><rect x="4" y="9" width="11" height="6" fill={p.fill || 'currentColor'} stroke="none"/></Icon>;
const IconGear = (p) => (
  <Icon {...p}>
    <circle cx="12" cy="12" r="3"/>
    <path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1"/>
  </Icon>
);

const IconSave = (p) => (
  <Icon {...p}>
    <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v13a2 2 0 0 1-2 2z"/>
    <polyline points="17 21 17 13 7 13 7 21"/>
    <polyline points="7 3 7 8 15 8"/>
  </Icon>
);

const IconStar = (p) => (
  <Icon {...p}>
    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
  </Icon>
);

const IconPlus = (p) => <Icon {...p}><path d="M12 5v14M5 12h14"/></Icon>;

Object.assign(window, {
  IconArrowUp, IconArrowDown, IconArrowLeft, IconArrowRight,
  IconCar, IconArm, IconHome, IconGrab, IconLift, IconRest,
  IconSend, IconClose, IconChevron, IconPower, IconBluetooth, IconSignal, IconBattery, IconGear,
  IconSave, IconStar, IconPlus
});
