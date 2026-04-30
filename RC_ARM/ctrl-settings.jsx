// Settings tab — per-servo threshold (min/max) configuration

function LimitStepper({ label, value, min, max, onChange }) {
  const dec = () => onChange(Math.max(min, value - 5));
  const inc = () => onChange(Math.min(max, value + 5));

  return (
    <div style={{
      display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
      background: '#0D0F0E', border: '1px solid #1F2623', borderRadius: 8,
      padding: '10px 8px', flex: 1
    }}>
      <div style={{
        fontFamily: 'Inter', fontSize: 9, letterSpacing: '0.2em',
        color: '#6B7B74', fontWeight: 600
      }}>{label}</div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <button onClick={dec} style={{
          width: 26, height: 26, borderRadius: 5,
          background: '#141716', border: '1px solid #1F2623',
          color: '#6B7B74', fontSize: 16, cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          lineHeight: 1, transition: 'border-color 0.12s'
        }}>−</button>
        <div style={{
          fontFamily: 'JetBrains Mono, monospace', fontSize: 17, fontWeight: 500,
          color: '#E6EEEA', letterSpacing: '0.04em', minWidth: 46, textAlign: 'center'
        }}>{value}°</div>
        <button onClick={inc} style={{
          width: 26, height: 26, borderRadius: 5,
          background: '#141716', border: '1px solid #1F2623',
          color: '#6B7B74', fontSize: 16, cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          lineHeight: 1, transition: 'border-color 0.12s'
        }}>+</button>
      </div>
    </div>
  );
}

function ServoLimitCard({ servo, limit, onUpdate }) {
  const range = limit.max - limit.min;
  return (
    <div style={{
      background: '#141716', border: '1px solid #1F2623',
      borderLeft: '2px solid #2A3830',
      borderRadius: 8, padding: '12px 14px', marginBottom: 8
    }}>
      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        marginBottom: 12
      }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
          <div style={{
            fontFamily: 'JetBrains Mono, monospace', fontWeight: 600, fontSize: 16,
            color: '#00E5A0', letterSpacing: '0.05em'
          }}>S{servo.id}</div>
          <div style={{
            fontFamily: 'Inter', fontSize: 10, color: '#6B7B74',
            letterSpacing: '0.12em', textTransform: 'uppercase'
          }}>{servo.name}</div>
        </div>
        <div style={{
          fontFamily: 'JetBrains Mono', fontSize: 10, color: '#3B4842',
          letterSpacing: '0.06em'
        }}>{range}° range</div>
      </div>
      <div style={{ display: 'flex', gap: 8 }}>
        <LimitStepper
          label="MIN"
          value={limit.min}
          min={0}
          max={limit.max - 5}
          onChange={v => onUpdate('min', v)}
        />
        <LimitStepper
          label="MAX"
          value={limit.max}
          min={limit.min + 5}
          max={270}
          onChange={v => onUpdate('max', v)}
        />
      </div>
    </div>
  );
}

function SettingsTab({ servos, servoLimits, onUpdateLimit }) {
  return (
    <div style={{ padding: 14 }}>
      <div style={{
        fontFamily: 'Inter', fontSize: 10, letterSpacing: '0.22em',
        color: '#6B7B74', fontWeight: 500, marginBottom: 12, paddingLeft: 2
      }}>SERVO THRESHOLDS</div>

      {servos.map((servo, idx) => (
        <ServoLimitCard
          key={servo.id}
          servo={servo}
          limit={servoLimits[idx]}
          onUpdate={(field, val) => onUpdateLimit(idx, field, val)}
        />
      ))}

      <div style={{
        fontFamily: 'JetBrains Mono, monospace', fontSize: 10,
        color: '#3B4842', padding: '8px 4px', lineHeight: 1.7,
        borderTop: '1px solid #1A1D1C', marginTop: 4
      }}>
        <span style={{ color: '#6B7B74' }}>·</span> Step size is 5°<br/>
        <span style={{ color: '#6B7B74' }}>·</span> Servo value is clamped when range narrows<br/>
        <span style={{ color: '#6B7B74' }}>·</span> Changes apply immediately
      </div>
    </div>
  );
}

Object.assign(window, { SettingsTab });
