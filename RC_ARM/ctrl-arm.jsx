// ARM tab — presets grid + 6 servo cards
function PresetButton({ icon: Icon, label, active, onClick }) {
  return (
    <button onClick={onClick} style={{
      padding: '12px 10px',
      background: active ? '#00E5A0' : '#141716',
      border: `1px solid ${active ? '#00E5A0' : '#1F2623'}`,
      borderRadius: 8,
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
      cursor: 'pointer',
      transition: 'all 0.15s',
      boxShadow: active ? '0 0 12px rgba(0,229,160,0.3)' : 'none'
    }}>
      <Icon size={20} strokeWidth={1.5} stroke={active ? '#0D0F0E' : '#E6EEEA'}/>
      <div style={{
        fontFamily: 'Inter', fontSize: 10, fontWeight: 700, letterSpacing: '0.2em',
        color: active ? '#0D0F0E' : '#E6EEEA'
      }}>{label}</div>
    </button>
  );
}

function ServoSlider({ value, onChange, max = 180 }) {
  const pct = (value / max) * 100;
  const tickMarks = max === 180 ? [0, 45, 90, 135, 180] : [0, 90, 180];
  
  return (
    <div style={{ position: 'relative', height: 26, marginTop: 4 }}>
      <div style={{
        position: 'absolute', top: 11, left: 0, right: 0, height: 3,
        background: '#0D0F0E', border: '1px solid #1F2623', borderRadius: 3
      }}/>
      <div style={{
        position: 'absolute', top: 11, left: 0, width: `${pct}%`, height: 3,
        background: '#00E5A0', borderRadius: 3,
        boxShadow: '0 0 6px rgba(0,229,160,0.4)'
      }}/>
      {/* Tick marks */}
      {tickMarks.map(t => (
        <div key={t} style={{
          position: 'absolute',
          top: 17, left: `${(t/max)*100}%`,
          width: 1, height: 5,
          background: '#6B7B74',
          transform: 'translateX(-0.5px)'
        }}/>
      ))}
      <input type="range" min={0} max={max} value={value}
        onChange={(e) => onChange(parseInt(e.target.value))}
        style={{
          position: 'absolute', inset: 0, width: '100%', height: '100%',
          margin: 0, opacity: 0, cursor: 'pointer'
        }}/>
      <div style={{
        position: 'absolute', top: 6, left: `calc(${pct}% - 6px)`,
        width: 12, height: 12, borderRadius: '50%',
        background: '#0D0F0E', border: '2px solid #00E5A0',
        boxShadow: '0 0 8px rgba(0,229,160,0.5)',
        pointerEvents: 'none',
        transition: 'left 0.1s'
      }}/>
    </div>
  );
}

function ServoCard({ servo, value, onChange }) {
  const max = servo.max || 180;
  const quickAngles = max === 180 ? [0, 45, 90, 135, 180] : [0, 90, 180];
  return (
    <div style={{
      background: '#141716',
      border: '1px solid #1F2623',
      borderLeft: '2px solid #00E5A0',
      borderRadius: 8,
      padding: '12px 14px',
      marginBottom: 8,
      position: 'relative'
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div style={{
            fontFamily: 'JetBrains Mono, monospace', fontWeight: 600, fontSize: 18,
            color: '#00E5A0', lineHeight: 1, letterSpacing: '0.05em'
          }}>S{servo.id}</div>
          <div style={{
            fontFamily: 'Inter', fontSize: 10, color: '#6B7B74',
            marginTop: 4, letterSpacing: '0.12em', textTransform: 'uppercase'
          }}>{servo.name}</div>
        </div>
        <div style={{
          display: 'flex', alignItems: 'baseline', gap: 2,
          fontFamily: 'JetBrains Mono, monospace'
        }}>
          <AnimatedAngle value={value} style={{
            fontSize: 22, fontWeight: 500, color: '#E6EEEA', letterSpacing: '-0.02em'
          }}/>
          <span style={{ fontSize: 14, color: '#6B7B74' }}>°</span>
        </div>
      </div>

      <div style={{ margin: '8px 0 10px' }}>
        <ServoSlider value={value} onChange={onChange} max={max}/>
      </div>

      {/* Quick angle chips */}
      <div style={{ display: 'flex', gap: 4 }}>
        {quickAngles.map(a => {
          const active = value === a;
          return (
            <button key={a} onClick={() => onChange(a)} style={{
              flex: 1, padding: '5px 0',
              background: active ? 'rgba(0,229,160,0.12)' : '#0D0F0E',
              border: `1px solid ${active ? '#00E5A0' : '#1F2623'}`,
              borderRadius: 4,
              color: active ? '#00E5A0' : '#6B7B74',
              fontFamily: 'JetBrains Mono, monospace',
              fontSize: 10, fontWeight: 500, letterSpacing: '0.02em',
              cursor: 'pointer',
              transition: 'all 0.12s'
            }}>{a}°</button>
          );
        })}
      </div>
    </div>
  );
}

function AnimatedAngle({ value, style }) {
  const [display, setDisplay] = useState(value);
  const prev = useRef(value);
  useEffect(() => {
    if (prev.current === value) return;
    const from = prev.current;
    const to = value;
    const duration = 240;
    const start = performance.now();
    let raf;
    const tick = (t) => {
      const p = Math.min(1, (t - start) / duration);
      const e = 1 - Math.pow(1 - p, 3);
      setDisplay(Math.round(from + (to - from) * e));
      if (p < 1) raf = requestAnimationFrame(tick);
      else prev.current = to;
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [value]);
  return <span style={style}>{String(display).padStart(3, '0')}</span>;
}

function ArmTab({ servos, onServo, preset, onPreset }) {
  const presets = [
    { id: 'home', label: 'HOME', icon: IconHome, values: [90, 90, 90, 90, 90] },
    { id: 'grab', label: 'GRAB', icon: IconGrab, values: [90, 120, 90, 60, 40] },
    { id: 'lift', label: 'LIFT', icon: IconLift, values: [90, 45, 90, 90, 90] },
    { id: 'rest', label: 'REST', icon: IconRest, values: [0, 0, 0, 0, 180] }
  ];

  return (
    <div style={{ padding: 14 }}>
      <div style={{
        fontFamily: 'Inter', fontSize: 10, letterSpacing: '0.22em',
        color: '#6B7B74', fontWeight: 500, marginBottom: 8, paddingLeft: 2
      }}>PRESET POSITIONS</div>
      <div style={{
        display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6,
        marginBottom: 14
      }}>
        {presets.map(p => (
          <PresetButton key={p.id} icon={p.icon} label={p.label}
            active={preset === p.id}
            onClick={() => onPreset(p)}/>
        ))}
      </div>

      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
        marginBottom: 8, paddingLeft: 2
      }}>
        <div style={{
          fontFamily: 'Inter', fontSize: 10, letterSpacing: '0.22em',
          color: '#6B7B74', fontWeight: 500
        }}>SERVOS · 6-DOF</div>
        <div style={{
          fontFamily: 'JetBrains Mono', fontSize: 10, color: '#00E5A0',
          letterSpacing: '0.1em'
        }}>● LIVE</div>
      </div>

      {servos.map((s, idx) => (
        <ServoCard key={s.id} servo={s} value={s.value} onChange={(v) => onServo(idx, v)}/>
      ))}
    </div>
  );
}

Object.assign(window, { ArmTab });
