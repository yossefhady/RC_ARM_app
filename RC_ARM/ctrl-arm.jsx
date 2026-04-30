// ARM tab — presets grid + 6 servo cards + save-to-preset picker

const ICON_MAP = {
  home: () => IconHome,
  grab: () => IconGrab,
  lift: () => IconLift,
  rest: () => IconRest,
  custom: () => IconStar
};

function resolveIcon(iconKey) {
  return (ICON_MAP[iconKey] || ICON_MAP.custom)();
}

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

function ServoSlider({ value, onChange, min = 0, max = 180 }) {
  const range = max - min;
  const pct = range > 0 ? ((value - min) / range) * 100 : 0;
  const tickCount = range >= 135 ? 5 : 3;
  const tickMarks = Array.from({ length: tickCount }, (_, i) =>
    Math.round(min + (range * i) / (tickCount - 1))
  );

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
      {tickMarks.map(t => (
        <div key={t} style={{
          position: 'absolute',
          top: 17, left: `${range > 0 ? ((t - min) / range) * 100 : 0}%`,
          width: 1, height: 5,
          background: '#6B7B74',
          transform: 'translateX(-0.5px)'
        }}/>
      ))}
      <input type="range" min={min} max={max} value={value}
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
  const min = servo.min ?? 0;
  const max = servo.max ?? 180;
  const range = max - min;
  const quickCount = range >= 135 ? 5 : 3;
  const quickAngles = Array.from({ length: quickCount }, (_, i) =>
    Math.round(min + (range * i) / (quickCount - 1))
  );

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
        <div style={{ textAlign: 'right' }}>
          <div style={{
            display: 'flex', alignItems: 'baseline', gap: 2,
            fontFamily: 'JetBrains Mono, monospace'
          }}>
            <AnimatedAngle value={value} style={{
              fontSize: 22, fontWeight: 500, color: '#E6EEEA', letterSpacing: '-0.02em'
            }}/>
            <span style={{ fontSize: 14, color: '#6B7B74' }}>°</span>
          </div>
          <div style={{
            fontFamily: 'JetBrains Mono', fontSize: 9, color: '#3B4842',
            letterSpacing: '0.06em', marginTop: 2
          }}>{min}–{max}</div>
        </div>
      </div>

      <div style={{ margin: '8px 0 10px' }}>
        <ServoSlider value={value} onChange={onChange} min={min} max={max}/>
      </div>

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

function SavePicker({ servos, presets, onSavePreset, onAddPreset, onClose }) {
  const [newName, setNewName] = useState('');

  const handleSaveTo = (presetId) => {
    onSavePreset(presetId, servos.map(s => s.value));
    onClose();
  };

  const handleAddNew = () => {
    if (!newName.trim()) return;
    onAddPreset(newName.trim(), servos.map(s => s.value));
    setNewName('');
    onClose();
  };

  return (
    <div style={{
      position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
      background: 'rgba(13,15,14,0.96)',
      zIndex: 20, borderRadius: 8,
      padding: 16,
      display: 'flex', flexDirection: 'column', gap: 12,
      minHeight: '100%'
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{
          fontFamily: 'Inter', fontSize: 10, letterSpacing: '0.22em',
          color: '#6B7B74', fontWeight: 500
        }}>SAVE POSITION TO</div>
        <button onClick={onClose} style={{
          background: 'none', border: 'none', cursor: 'pointer',
          color: '#6B7B74', padding: 4, display: 'flex'
        }}>
          <IconClose size={16} strokeWidth={1.8}/>
        </button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
        {presets.map(p => {
          const Icon = resolveIcon(p.icon);
          return (
            <button key={p.id} onClick={() => handleSaveTo(p.id)} style={{
              padding: '12px 10px',
              background: '#141716',
              border: '1px solid #1F2623',
              borderRadius: 8,
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
              cursor: 'pointer',
              transition: 'border-color 0.15s'
            }}>
              <Icon size={20} strokeWidth={1.5} stroke='#E6EEEA'/>
              <div style={{
                fontFamily: 'Inter', fontSize: 10, fontWeight: 700,
                letterSpacing: '0.2em', color: '#E6EEEA'
              }}>{p.label}</div>
            </button>
          );
        })}
      </div>

      <div style={{
        border: '1px solid #1F2623', borderRadius: 8, overflow: 'hidden'
      }}>
        <div style={{
          padding: '8px 12px', borderBottom: '1px solid #1F2623',
          background: 'rgba(0,229,160,0.04)'
        }}>
          <div style={{
            fontFamily: 'Inter', fontSize: 9, letterSpacing: '0.2em',
            color: '#6B7B74', fontWeight: 600, display: 'flex', alignItems: 'center', gap: 5
          }}>
            <IconPlus size={10} strokeWidth={2.5} stroke='#6B7B74'/> NEW PRESET
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8, padding: 10 }}>
          <input
            value={newName}
            onChange={e => setNewName(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && handleAddNew()}
            placeholder="Enter name…"
            style={{
              flex: 1, background: '#0D0F0E',
              border: '1px solid #1F2623', borderRadius: 6,
              padding: '8px 10px',
              fontFamily: 'JetBrains Mono, monospace', fontSize: 11,
              color: '#E6EEEA', outline: 'none', caretColor: '#00E5A0'
            }}
          />
          <button onClick={handleAddNew} style={{
            padding: '0 14px',
            background: newName.trim() ? '#00E5A0' : '#141716',
            border: `1px solid ${newName.trim() ? '#00E5A0' : '#1F2623'}`,
            borderRadius: 6,
            color: newName.trim() ? '#0D0F0E' : '#6B7B74',
            fontFamily: 'Inter', fontSize: 11, fontWeight: 700,
            letterSpacing: '0.1em', cursor: 'pointer',
            transition: 'all 0.15s'
          }}>ADD</button>
        </div>
      </div>
    </div>
  );
}

function ArmTab({ servos, servoLimits, onServo, preset, onPreset, presets, onSavePreset, onAddPreset }) {
  const [showSavePicker, setShowSavePicker] = useState(false);

  return (
    <div style={{ padding: 14, position: 'relative' }}>
      {showSavePicker && (
        <SavePicker
          servos={servos}
          presets={presets}
          onSavePreset={onSavePreset}
          onAddPreset={onAddPreset}
          onClose={() => setShowSavePicker(false)}
        />
      )}

      <div style={{
        fontFamily: 'Inter', fontSize: 10, letterSpacing: '0.22em',
        color: '#6B7B74', fontWeight: 500, marginBottom: 8, paddingLeft: 2
      }}>PRESET POSITIONS</div>
      <div style={{
        display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6,
        marginBottom: 14
      }}>
        {presets.map(p => {
          const Icon = resolveIcon(p.icon);
          return (
            <PresetButton key={p.id} icon={Icon} label={p.label}
              active={preset === p.id}
              onClick={() => onPreset(p)}/>
          );
        })}
      </div>

      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        marginBottom: 8, paddingLeft: 2
      }}>
        <div style={{
          fontFamily: 'Inter', fontSize: 10, letterSpacing: '0.22em',
          color: '#6B7B74', fontWeight: 500
        }}>SERVOS · 6-DOF</div>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <div style={{
            fontFamily: 'JetBrains Mono', fontSize: 10, color: '#00E5A0',
            letterSpacing: '0.1em'
          }}>● LIVE</div>
          <button
            onClick={() => setShowSavePicker(true)}
            style={{
              display: 'flex', alignItems: 'center', gap: 5,
              padding: '4px 10px',
              background: 'rgba(0,229,160,0.06)',
              border: '1px solid rgba(0,229,160,0.25)',
              borderRadius: 5,
              fontFamily: 'JetBrains Mono, monospace', fontSize: 9,
              letterSpacing: '0.12em', color: '#00E5A0',
              cursor: 'pointer', transition: 'background 0.15s'
            }}
          >
            <IconSave size={11} strokeWidth={1.8}/> SAVE
          </button>
        </div>
      </div>

      {servos.map((s, idx) => {
        const limit = (servoLimits && servoLimits[idx]) || { min: 0, max: s.max || 180 };
        return (
          <ServoCard
            key={s.id}
            servo={{ ...s, min: limit.min, max: limit.max }}
            value={s.value}
            onChange={(v) => onServo(idx, v)}
          />
        );
      })}
    </div>
  );
}

Object.assign(window, { ArmTab });
