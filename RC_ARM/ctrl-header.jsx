// Header — logo, app title, connection pill, signal bar
const { useState, useEffect, useRef, useMemo } = React;

function StatusDot({ connected }) {
  return (
    <span style={{
      display: 'inline-block', width: 8, height: 8, borderRadius: '50%',
      background: connected ? '#00E5A0' : '#FF4D4D',
      boxShadow: connected ? '0 0 8px rgba(0,229,160,0.8)' : '0 0 8px rgba(255,77,77,0.8)',
      animation: connected ? 'ctrlPulse 1.6s ease-in-out infinite' : 'none',
      flexShrink: 0
    }}/>
  );
}

function CTRLHeader({ connected, onToggleConnection, batteryLevel = 78, rssi = -54 }) {
  const [tick, setTick] = useState(0);
  useEffect(() => {
    const id = setInterval(() => setTick(t => t + 1), 800);
    return () => clearInterval(id);
  }, []);

  // Signal strength bars data (animated subtly)
  const bars = useMemo(() => {
    if (!connected) return [0,0,0,0,0,0,0,0,0,0,0,0];
    return Array.from({ length: 24 }, (_, i) => {
      const base = Math.sin((tick * 0.3) + i * 0.4) * 0.3 + 0.6;
      return Math.max(0.15, Math.min(1, base + (i % 5 === 0 ? 0.15 : 0)));
    });
  }, [tick, connected]);

  const latency = connected ? 18 + (tick % 7) : 999;

  return (
    <div style={{
      padding: '58px 16px 0',
      background: 'linear-gradient(180deg, rgba(0,229,160,0.04), transparent 80%)',
      borderBottom: '1px solid #1F2623'
    }}>
      {/* Top row: logo + pill */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 32, height: 32, borderRadius: 8,
            background: '#141716', border: '1px solid #1F2623',
            display: 'grid', placeItems: 'center', overflow: 'hidden'
          }}>
            <img src="assets/technogenius-logo.png" alt="TG"
              style={{ width: '160%', height: '160%', objectFit: 'cover', objectPosition: 'center 18%', transform: 'translateY(-2px)' }}/>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1 }}>
            <div style={{
              fontFamily: 'JetBrains Mono, monospace',
              fontWeight: 700, fontSize: 18, letterSpacing: '0.12em', color: '#E6EEEA',
              display: 'flex', alignItems: 'center', gap: 8
            }}>
              CTRL
              <StatusDot connected={connected}/>
            </div>
            <div style={{
              fontFamily: 'Inter, sans-serif',
              fontSize: 9, letterSpacing: '0.25em', color: '#6B7B74', marginTop: 3,
              textTransform: 'uppercase'
            }}>Techno Genius · RC Ops</div>
          </div>
        </div>

        <button onClick={onToggleConnection} style={{
          cursor: 'pointer', border: 'none', background: 'transparent', padding: 0
        }}>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 6,
            padding: '6px 10px',
            background: connected ? 'rgba(0,229,160,0.08)' : 'rgba(255,77,77,0.06)',
            border: `1px solid ${connected ? 'rgba(0,229,160,0.35)' : 'rgba(255,77,77,0.3)'}`,
            borderRadius: 999,
            fontFamily: 'JetBrains Mono, monospace',
            fontSize: 10, letterSpacing: '0.1em',
            color: connected ? '#00E5A0' : '#FF4D4D'
          }}>
            <IconBluetooth size={12} strokeWidth={2}/>
            <span>{connected ? 'CONNECTED · ESP32' : 'NO SIGNAL'}</span>
          </div>
        </button>
      </div>

      {/* Signal + telemetry row */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 12,
        paddingBottom: 10
      }}>
        {/* Bars viz */}
        <div style={{
          flex: 1, height: 22, display: 'flex', gap: 2, alignItems: 'flex-end',
          padding: '0 2px'
        }}>
          {bars.map((b, i) => (
            <div key={i} style={{
              flex: 1, height: `${b * 100}%`, minHeight: 3,
              background: connected
                ? `linear-gradient(180deg, rgba(0,229,160,${0.4 + b * 0.5}), rgba(0,229,160,${0.15 + b * 0.2}))`
                : 'rgba(107,123,116,0.2)',
              borderRadius: 1,
              transition: 'height 0.3s ease'
            }}/>
          ))}
        </div>

        {/* Telemetry */}
        <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
          <TelemetryReadout label="LAT" value={connected ? `${String(latency).padStart(2,'0')}ms` : '---'} accent={connected}/>
          <TelemetryReadout label="RSSI" value={connected ? `${rssi}` : '---'} accent={connected}/>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 4,
            fontFamily: 'JetBrains Mono, monospace',
            fontSize: 11, color: batteryLevel > 20 ? '#00E5A0' : '#FF4D4D'
          }}>
            <IconBattery size={14} strokeWidth={1.5}/>
            <span>{batteryLevel}%</span>
          </div>
        </div>
      </div>
    </div>
  );
}

function TelemetryReadout({ label, value, accent }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', lineHeight: 1 }}>
      <div style={{ fontFamily: 'Inter', fontSize: 8, letterSpacing: '0.2em', color: '#6B7B74' }}>{label}</div>
      <div style={{
        fontFamily: 'JetBrains Mono, monospace', fontWeight: 500, fontSize: 11,
        color: accent ? '#00E5A0' : '#6B7B74', marginTop: 3
      }}>{value}</div>
    </div>
  );
}

// Tab bar
function TabBar({ active, onChange }) {
  const tabs = [
    { id: 'drive', label: 'DRIVE', icon: IconCar },
    { id: 'arm', label: 'ARM', icon: IconArm }
  ];
  return (
    <div style={{
      display: 'flex', position: 'relative',
      background: '#0D0F0E',
      borderBottom: '1px solid #1F2623'
    }}>
      {tabs.map((tab) => {
        const isActive = active === tab.id;
        return (
          <button key={tab.id} onClick={() => onChange(tab.id)} style={{
            flex: 1, padding: '14px 0',
            background: 'transparent', border: 'none',
            cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            fontFamily: 'Inter, sans-serif',
            fontSize: 12, fontWeight: 600, letterSpacing: '0.18em',
            color: isActive ? '#E6EEEA' : '#6B7B74',
            position: 'relative',
            transition: 'color 0.2s'
          }}>
            <tab.icon size={18} strokeWidth={1.5} stroke={isActive ? '#00E5A0' : '#6B7B74'}/>
            <span>{tab.label}</span>
          </button>
        );
      })}
      {/* Sliding underline */}
      <div style={{
        position: 'absolute', bottom: -1, height: 2,
        left: active === 'drive' ? '10%' : '60%',
        width: '30%',
        background: '#00E5A0',
        boxShadow: '0 0 8px rgba(0,229,160,0.6)',
        transition: 'left 0.3s cubic-bezier(0.65, 0, 0.35, 1)'
      }}/>
    </div>
  );
}

Object.assign(window, { CTRLHeader, TabBar, StatusDot });
