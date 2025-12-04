import React from 'react'

const StyleTestPage: React.FC = () => {
  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-4xl font-bold text-blue-600 mb-8">Style Test Page</h1>
        
        <div className="grid md:grid-cols-2 gap-6">
          {/* Buttons Test */}
          <div className="card">
            <h2 className="text-2xl font-semibold mb-4">Buttons</h2>
            <div className="space-y-4">
              <button className="btn btn-primary">Primary Button</button>
              <button className="btn btn-secondary">Secondary Button</button>
              <button className="btn btn-danger">Danger Button</button>
            </div>
          </div>

          {/* Forms Test */}
          <div className="card">
            <h2 className="text-2xl font-semibold mb-4">Forms</h2>
            <div className="space-y-4">
              <input className="input" placeholder="Test input field" />
              <select className="input">
                <option>Select option</option>
                <option>Option 1</option>
                <option>Option 2</option>
              </select>
            </div>
          </div>

          {/* Colors Test */}
          <div className="card">
            <h2 className="text-2xl font-semibold mb-4">Colors</h2>
            <div className="grid grid-cols-4 gap-4">
              <div className="w-16 h-16 bg-blue-500 rounded-lg"></div>
              <div className="w-16 h-16 bg-green-500 rounded-lg"></div>
              <div className="w-16 h-16 bg-red-500 rounded-lg"></div>
              <div className="w-16 h-16 bg-purple-500 rounded-lg"></div>
            </div>
          </div>

          {/* Typography Test */}
          <div className="card">
            <h2 className="text-2xl font-semibold mb-4">Typography</h2>
            <div className="space-y-2">
              <h3 className="text-lg font-medium">Medium text</h3>
              <p className="text-gray-600">Regular paragraph text</p>
              <p className="text-sm text-gray-500">Small muted text</p>
            </div>
          </div>
        </div>

        <div className="mt-8 p-4" style={{ backgroundColor: '#d1fae5', border: '1px solid #a7f3d0', borderRadius: '0.5rem' }}>
          <p style={{ color: '#065f46' }}>
            ✅ If you can see this styled properly, CSS is working perfectly!
          </p>
        </div>

        <div className="mt-4 p-4" style={{ backgroundColor: '#fef3c7', border: '1px solid #fcd34d', borderRadius: '0.5rem' }}>
          <p style={{ color: '#92400e' }}>
            🎨 Custom CSS styling system is active!
          </p>
        </div>

        {/* Fallback styles */}
        <div style={{
          marginTop: '2rem',
          padding: '1rem',
          backgroundColor: '#fee2e2',
          border: '1px solid #fca5a5',
          borderRadius: '0.5rem'
        }}>
          <p style={{ color: '#991b1b' }}>
            🚨 If only this box looks styled, Tailwind is not loading and we're using fallback styles.
          </p>
        </div>
      </div>
    </div>
  )
}

export default StyleTestPage