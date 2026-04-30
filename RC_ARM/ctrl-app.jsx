// CTRL — main app wiring everything together
const { createRoot } = ReactDOM;

const DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "#00E5A0",
  "showTerminal": true,
  "showLogo": true,
  "hudDensity": "normal"
}/*EDITMODE-END*/;

const SERVO_NAMES = [
  { id: 1, name: 'BASE ROT',   min: 0, max: 180 },
  { id: 2, name: 'SHOULDER',   min: 0, max: 180 },
  { id: 4, name: 'ELBOW',      min: 0, max: 180 },
  { id: 5, name: 'WRIST ROLL', min: 0, max: 180 },
  { id: 6, name: 'GRIPPER',    min: 0, max: 180 }
];

const INITIAL_PRESETS = [
  { id: 'home', label: 'HOME', icon: 'home', values: [90, 90, 90, 90, 90] },
  { id: 'grab', label: 'GRAB', icon: 'grab', values: [90, 120, 90, 60, 40] },
  { id: 'lift', label: 'LIFT', icon: 'lift', values: [90, 45, 90, 90, 90] },
  { id: 'rest', label: 'REST', icon: 'rest', values: [0, 0, 0, 0, 180] }
];

function ts() {
  const d = new Date();
  return `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}:${String(d.getSeconds()).padStart(2,'0')}`;
}

function App() {
  const [tweaks, setTweaks] = useTweaks(DEFAULTS);
  const [tab, setTab] = useState('drive');
  const [connected, setConnected] = useState(true);
  const [speed, setSpeed] = useState(180);
  const [mode, setMode] = useState('forward');
  const [servos, setServos] = useState(SERVO_NAMES.map(s => ({ ...s, value: 90 })));
  const [preset, setPreset] = useState('home');
  const [presets, setPresets] = useState(INITIAL_PRESETS);
  const [servoLimits, setServoLimits] = useState(SERVO_NAMES.map(s => ({ min: s.min, max: s.max })));
  const servoTimers = useRef({});
  const [logs, setLogs] = useState([
    { ts: ts(), type: 'info', msg: 'BLE link established · ESP32-WROOM-32' },
    { ts: ts(), type: 'in', msg: 'ACK handshake · firmware v2.4.1' },
    { ts: ts(), type: 'out', msg: 'SET_PWM 180' },
    { ts: ts(), type: 'in', msg: 'OK · pwm=180' },
    { ts: ts(), type: 'out', msg: 'ARM_HOME' },
    { ts: ts(), type: 'in', msg: 'OK · servos aligned 90°' }
  ]);

  const addLog = (type, msg) => {
    setLogs(l => [...l.slice(-40), { ts: ts(), type, msg }]);
  };

  // ── Drive handlers ───────────────────────────────────────────────────────
  const onDirection = (dir, pressed) => {
    if (!pressed) return;
    const cmdMap = {
      up: 'DRIVE_FWD', down: 'DRIVE_REV',
      left: 'TURN_L', right: 'TURN_R',
      stop: 'DRIVE_STOP'
    };
    addLog('out', `${cmdMap[dir]} pwm=${speed}`);
    setTimeout(() => addLog('in', dir === 'stop' ? 'OK · halted' : `OK · ${cmdMap[dir].toLowerCase()}`), 120);
  };

  const onSpeed = (v) => setSpeed(v);

  useEffect(() => {
    const id = setTimeout(() => addLog('out', `SET_PWM ${speed}`), 300);
    return () => clearTimeout(id);
  }, [speed]);

  const onMode = (m) => {
    setMode(m.id);
    setSpeed(m.speed);
    addLog('out', `MODE ${m.id.toUpperCase()} · pwm=${m.speed}`);
    setTimeout(() => addLog('in', `OK · mode=${m.id}`), 120);
  };

  // ── Arm handlers ─────────────────────────────────────────────────────────
  // Debounce: update visual state immediately, delay BLE command 150 ms
  const onServo = (idx, v) => {
    const servoId = SERVO_NAMES[idx].id;
    setServos(s => s.map((sv, i) => i === idx ? { ...sv, value: v } : sv));
    setPreset(null);
    clearTimeout(servoTimers.current[idx]);
    servoTimers.current[idx] = setTimeout(() => {
      addLog('out', `S${servoId} → ${String(v).padStart(3,'0')}°`);
    }, 150);
  };

  const onPreset = (p) => {
    setPreset(p.id);
    setServos(s => s.map((sv, i) => ({ ...sv, value: p.values[i] })));
    addLog('out', `PRESET ${p.label}`);
    setTimeout(() => addLog('in', `OK · moving to ${p.label.toLowerCase()}`), 120);
  };

  const onSavePreset = (presetId, values) => {
    setPresets(prev => prev.map(p => p.id === presetId ? { ...p, values } : p));
    addLog('out', `PRESET SAVE → ${presetId.toUpperCase()}`);
    setTimeout(() => addLog('in', 'OK · preset updated'), 120);
  };

  const onAddPreset = (label, values) => {
    const id = `custom_${Date.now()}`;
    setPresets(prev => [...prev, { id, label: label.toUpperCase(), icon: 'custom', values }]);
    addLog('out', `PRESET ADD → ${label.toUpperCase()}`);
    setTimeout(() => addLog('in', 'OK · preset saved'), 120);
  };

  // ── Settings handlers ────────────────────────────────────────────────────
  const onUpdateLimit = (idx, field, val) => {
    setServoLimits(prev => prev.map((l, i) => i === idx ? { ...l, [field]: val } : l));
    // Clamp servo value to new range
    setServos(s => s.map((sv, i) => {
      if (i !== idx) return sv;
      const newVal = field === 'max'
        ? Math.min(sv.value, val)
        : Math.max(sv.value, val);
      return { ...sv, value: newVal };
    }));
  };

  // ── Terminal handler ──────────────────────────────────────────────────────
  const onSendCommand = (cmd) => {
    addLog('out', cmd);
    setTimeout(() => {
      if (cmd.toLowerCase().startsWith('err')) {
        addLog('err', 'unknown command');
      } else {
        addLog('in', 'OK');
      }
    }, 150);
  };

  return (
    <>
      <style>{`
        @keyframes ctrlPulse {
          0%, 100% { opacity: 1; transform: scale(1); }
          50% { opacity: 0.5; transform: scale(0.85); }
        }
        @keyframes ctrlBlink {
          0%, 100% { opacity: 1; }
          50% { opacity: 0; }
        }
        ::-webkit-scrollbar { width: 4px; height: 4px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #1F2623; border-radius: 2px; }
      `}</style>

      <IOSDevice width={390} height={844} dark={true}>
        <div style={{
          height: '100%',
          background: '#0D0F0E',
          display: 'flex', flexDirection: 'column',
          overflow: 'hidden',
          position: 'relative'
        }}>
          <CTRLHeader
            connected={connected}
            onToggleConnection={() => setConnected(c => !c)}
          />
          <TabBar active={tab} onChange={setTab}/>

          <div style={{ flex: 1, overflowY: 'auto', overflowX: 'hidden', paddingBottom: 40 }}>
            {tab === 'drive' && (
              <DriveTab
                speed={speed} onSpeed={onSpeed}
                onDirection={onDirection}
                mode={mode} onMode={onMode}
              />
            )}
            {tab === 'arm' && (
              <ArmTab
                servos={servos}
                servoLimits={servoLimits}
                onServo={onServo}
                preset={preset}
                onPreset={onPreset}
                presets={presets}
                onSavePreset={onSavePreset}
                onAddPreset={onAddPreset}
              />
            )}
            {tab === 'settings' && (
              <SettingsTab
                servos={servos}
                servoLimits={servoLimits}
                onUpdateLimit={onUpdateLimit}
              />
            )}

            {tweaks.showTerminal && (
              <Terminal logs={logs} onSend={onSendCommand}/>
            )}
          </div>
        </div>
      </IOSDevice>

      <TweaksPanel>
        <TweakSection title="Display">
          <TweakToggle label="Show command terminal"
            value={tweaks.showTerminal}
            onChange={(v) => setTweaks({ showTerminal: v })}/>
          <TweakToggle label="Show TG logo"
            value={tweaks.showLogo}
            onChange={(v) => setTweaks({ showLogo: v })}/>
        </TweakSection>
        <TweakSection title="Simulate">
          <TweakButton label={connected ? 'Disconnect BLE' : 'Reconnect BLE'}
            onClick={() => {
              setConnected(c => !c);
              addLog('info', connected ? 'BLE disconnected' : 'BLE reconnecting…');
            }}/>
          <TweakButton label="Trigger error log"
            onClick={() => addLog('err', 'servo S3 · torque overload')}/>
          <TweakButton label="Clear log"
            onClick={() => setLogs([])}/>
        </TweakSection>
        <TweakSection title="Live state">
          <div style={{
            fontFamily: 'JetBrains Mono, monospace', fontSize: 11,
            color: '#6B7B74', padding: '4px 0', lineHeight: 1.8
          }}>
            <div>tab = <span style={{color:'#00E5A0'}}>{tab}</span></div>
            <div>speed = <span style={{color:'#00E5A0'}}>{speed}</span></div>
            <div>preset = <span style={{color:'#00E5A0'}}>{preset || 'custom'}</span></div>
            <div>logs = <span style={{color:'#00E5A0'}}>{logs.length}</span></div>
          </div>
        </TweakSection>
      </TweaksPanel>
    </>
  );
}

const root = createRoot(document.getElementById('stage'));
root.render(<App/>);
