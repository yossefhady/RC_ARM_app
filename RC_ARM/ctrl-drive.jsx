// DRIVE tab — speed slider, D-pad, mode chips
function SpeedSlider({ value, onChange }) {
  const pct = (value / 255) * 100;
  return (
    <div style={{
      padding: '14px 16px',
      background: '#141716',
      border: '1px solid #1F2623',
      borderRadius: 12,
      marginBottom: 14
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 10 }}>
        <div style={{
          fontFamily: 'Inter', fontSize: 10, letterSpacing: '0.22em',
          color: '#6B7B74', fontWeight: 500
        }}>PWM SPEED</div>
        <div style={{
          display: 'flex', alignItems: 'baseline', gap: 4,
          fontFamily: 'JetBrains Mono, monospace'
        }}>
          <AnimatedNumber value={value} style={{
            fontSize: 32, fontWeight: 500, color: '#00E5A0',
            letterSpacing: '-0.02em',
            textShadow: '0 0 12px rgba(0,229,160,0.35)'
          }}/>
          <div style={{ fontSize: 10, color: '#6B7B74', letterSpacing: '0.1em' }}>/ 255</div>
        </div>
      </div>
      <div style={{ position: 'relative', height: 28 }}>
        {/* Track */}
        <div style={{
          position: 'absolute', top: 12, left: 0, right: 0, height: 4,
          background: '#0D0F0E', border: '1px solid #1F2623', borderRadius: 4
        }}/>
        {/* Fill */}
        <div style={{
          position: 'absolute', top: 12, left: 0, width: `${pct}%`, height: 4,
          background: 'linear-gradient(90deg, rgba(0,229,160,0.6), #00E5A0)',
          borderRadius: 4,
          boxShadow: '0 0 8px rgba(0,229,160,0.4)'
        }}/>
        {/* Tick marks */}
        <div style={{ position: 'absolute', top: 20, left: 0, right: 0, display: 'flex', justifyContent: 'space-between' }}>
          {Array.from({ length: 11 }, (_, i) => (
            <div key={i} style={{
              width: 1, height: i % 5 === 0 ? 6 : 3,
              background: i % 5 === 0 ? '#6B7B74' : '#1F2623'
            }}/>
          ))}
        </div>
        <input type="range" min={0} max={255} value={value}
          onChange={(e) => onChange(parseInt(e.target.value))}
          style={{
            position: 'absolute', inset: 0,
            width: '100%', height: '100%', margin: 0, opacity: 0, cursor: 'pointer'
          }}/>
        {/* Thumb */}
        <div style={{
          position: 'absolute', top: 6, left: `calc(${pct}% - 8px)`,
          width: 16, height: 16, borderRadius: '50%',
          background: '#00E5A0', border: '2px solid #0D0F0E',
          boxShadow: '0 0 0 1px #00E5A0, 0 0 12px rgba(0,229,160,0.6)',
          pointerEvents: 'none',
          transition: 'left 0.08s'
        }}/>
      </div>
    </div>
  );
}

function AnimatedNumber({ value, style }) {
  const [display, setDisplay] = useState(value);
  const prev = useRef(value);
  useEffect(() => {
    if (prev.current === value) return;
    const from = prev.current;
    const to = value;
    const duration = 200;
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
  return <div style={style}>{String(display).padStart(3, '0')}</div>;
}

function DPadButton({ icon: Icon, onPress, pressed, size = 72, variant = 'default' }) {
  const isStop = variant === 'stop';
  return (
    <button
      onPointerDown={() => onPress(true)}
      onPointerUp={() => onPress(false)}
      onPointerLeave={() => onPress(false)}
      style={{
        width: size, height: size,
        background: pressed
          ? (isStop ? 'rgba(255,77,77,0.15)' : 'rgba(0,229,160,0.15)')
          : '#141716',
        border: `1px solid ${pressed ? (isStop ? '#FF4D4D' : '#00E5A0') : '#1F2623'}`,
        borderRadius: isStop ? 14 : 10,
        display: 'grid', placeItems: 'center',
        cursor: 'pointer',
        transform: pressed ? 'scale(0.94)' : 'scale(1)',
        transition: 'transform 0.08s, background 0.12s, border-color 0.12s',
        boxShadow: pressed
          ? (isStop ? '0 0 16px rgba(255,77,77,0.4), inset 0 0 8px rgba(255,77,77,0.15)' : '0 0 16px rgba(0,229,160,0.4), inset 0 0 8px rgba(0,229,160,0.15)')
          : 'none',
        clipPath: isStop ? 'polygon(30% 0%, 70% 0%, 100% 30%, 100% 70%, 70% 100%, 30% 100%, 0% 70%, 0% 30%)' : 'none'
      }}>
      {isStop ? (
        <div style={{
          fontFamily: 'JetBrains Mono, monospace', fontWeight: 700, fontSize: 14,
          letterSpacing: '0.15em', color: pressed ? '#FF4D4D' : '#E6EEEA'
        }}>STOP</div>
      ) : (
        <Icon size={28} strokeWidth={1.5} stroke={pressed ? '#00E5A0' : '#E6EEEA'}/>
      )}
    </button>
  );
}

function DPad({ onDirection }) {
  const [pressed, setPressed] = useState({});
  const set = (dir, v) => {
    setPressed(p => ({ ...p, [dir]: v }));
    onDirection(dir, v);
  };
  return (
    <div style={{
      padding: '14px',
      background: '#0D0F0E',
      border: '1px solid #1F2623',
      borderRadius: 12,
      marginBottom: 14,
      position: 'relative',
      overflow: 'hidden'
    }}>
      {/* HUD decoration */}
      <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', pointerEvents: 'none' }}
        viewBox="0 0 100 100" preserveAspectRatio="none">
        <circle cx="50" cy="50" r="42" fill="none" stroke="rgba(0,229,160,0.08)" strokeWidth="0.15" strokeDasharray="1 2"/>
        <circle cx="50" cy="50" r="30" fill="none" stroke="rgba(0,229,160,0.06)" strokeWidth="0.15"/>
      </svg>

      {/* Corner brackets */}
      {[[0,0],[100,0],[0,100],[100,100]].map(([x,y], i) => (
        <svg key={i} style={{
          position: 'absolute', width: 14, height: 14,
          left: x === 0 ? 8 : 'auto', right: x === 100 ? 8 : 'auto',
          top: y === 0 ? 8 : 'auto', bottom: y === 100 ? 8 : 'auto',
          opacity: 0.45
        }} viewBox="0 0 14 14">
          <path d={
            x === 0 && y === 0 ? 'M1 6V1H6' :
            x === 100 && y === 0 ? 'M13 6V1H8' :
            x === 0 && y === 100 ? 'M1 8V13H6' :
            'M13 8V13H8'
          } stroke="#00E5A0" strokeWidth="1" fill="none"/>
        </svg>
      ))}

      <div style={{
        display: 'flex', justifyContent: 'space-between',
        padding: '4px 6px 10px', alignItems: 'center'
      }}>
        <div style={{
          fontFamily: 'Inter', fontSize: 10, letterSpacing: '0.22em',
          color: '#6B7B74', fontWeight: 500
        }}>DIRECTION · MANUAL</div>
        <div style={{
          fontFamily: 'JetBrains Mono', fontSize: 10, color: '#00E5A0',
          letterSpacing: '0.1em'
        }}>
          {pressed.up ? 'FWD' : pressed.down ? 'REV' : pressed.left ? 'L-TURN' : pressed.right ? 'R-TURN' : 'IDLE'}
        </div>
      </div>

      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 1fr)',
        gap: 8,
        justifyItems: 'center',
        position: 'relative'
      }}>
        {/* crosshair bg */}
        <svg style={{
          position: 'absolute', width: 200, height: 200,
          left: '50%', top: '50%', transform: 'translate(-50%, -50%)',
          pointerEvents: 'none', opacity: 0.15
        }} viewBox="0 0 200 200">
          <circle cx="100" cy="100" r="90" fill="none" stroke="#00E5A0" strokeWidth="0.5"/>
          <line x1="100" y1="10" x2="100" y2="30" stroke="#00E5A0" strokeWidth="0.5"/>
          <line x1="100" y1="170" x2="100" y2="190" stroke="#00E5A0" strokeWidth="0.5"/>
          <line x1="10" y1="100" x2="30" y2="100" stroke="#00E5A0" strokeWidth="0.5"/>
          <line x1="170" y1="100" x2="190" y2="100" stroke="#00E5A0" strokeWidth="0.5"/>
        </svg>

        <div/>
        <DPadButton icon={IconArrowUp} onPress={(v) => set('up', v)} pressed={pressed.up}/>
        <div/>
        <DPadButton icon={IconArrowLeft} onPress={(v) => set('left', v)} pressed={pressed.left}/>
        <DPadButton icon={IconArrowUp} onPress={(v) => set('stop', v)} pressed={pressed.stop} variant="stop"/>
        <DPadButton icon={IconArrowRight} onPress={(v) => set('right', v)} pressed={pressed.right}/>
        <div/>
        <DPadButton icon={IconArrowDown} onPress={(v) => set('down', v)} pressed={pressed.down}/>
        <div/>
      </div>
    </div>
  );
}

function ModeChips({ mode, onMode }) {
  const modes = [
    { id: 'forward', label: 'FORWARD ONLY', speed: 255 },
    { id: 'tank', label: 'TANK SPIN', speed: 150 },
    { id: 'crawl', label: 'CRAWL', speed: 60 }
  ];
  return (
    <div style={{ display: 'flex', gap: 6 }}>
      {modes.map(m => {
        const active = mode === m.id;
        return (
          <button key={m.id} onClick={() => onMode(m)} style={{
            flex: 1,
            padding: '9px 4px',
            background: active ? 'rgba(0,229,160,0.1)' : '#141716',
            border: `1px solid ${active ? '#00E5A0' : '#1F2623'}`,
            borderRadius: 6,
            color: active ? '#00E5A0' : '#6B7B74',
            fontFamily: 'Inter', fontSize: 9, fontWeight: 600,
            letterSpacing: '0.18em',
            cursor: 'pointer',
            transition: 'all 0.15s',
            boxShadow: active ? '0 0 10px rgba(0,229,160,0.25)' : 'none'
          }}>{m.label}</button>
        );
      })}
    </div>
  );
}

function DriveTab({ speed, onSpeed, onDirection, mode, onMode }) {
  return (
    <div style={{ padding: 14 }}>
      <SpeedSlider value={speed} onChange={onSpeed}/>
      <DPad onDirection={onDirection}/>
      <div style={{
        fontFamily: 'Inter', fontSize: 10, letterSpacing: '0.22em',
        color: '#6B7B74', fontWeight: 500, marginBottom: 8, paddingLeft: 2
      }}>PRESETS</div>
      <ModeChips mode={mode} onMode={onMode}/>
    </div>
  );
}

Object.assign(window, { DriveTab, AnimatedNumber });
