mod editor;

use winit::{
    event::*,
    event_loop::EventLoop,
    keyboard::{KeyCode, PhysicalKey},
    window::WindowBuilder,
};

pub async fn run() {
    env_logger::init();
    let event_loop = EventLoop::new().unwrap();
    let window = WindowBuilder::new().build(&event_loop).unwrap();

    let mut editor = editor::Editor::new(&window).await;

    event_loop.run(move |event, control_flow| match event {
        Event::WindowEvent {
            ref event,
            window_id,
        } if window_id == editor.window().id() => {
            if !editor.input(event) {
                match event {
                    WindowEvent::CloseRequested
                    | WindowEvent::KeyboardInput {
                        event:
                            KeyEvent {
                                state: ElementState::Pressed,
                                physical_key: PhysicalKey::Code(KeyCode::Escape),
                                ..
                            },
                        ..
                    } => control_flow.exit(),
                    WindowEvent::Resized(new_size) => {
                        editor.resize(*new_size);
                    }
                    WindowEvent::RedrawRequested => {
                        editor.window().request_redraw();

                        editor.update();
                        match editor.render() {
                            Ok(_) => {}
                            Err(wgpu::SurfaceError::Lost | wgpu::SurfaceError::Outdated) => {
                                editor.resize(editor.size)
                            }
                            Err(wgpu::SurfaceError::OutOfMemory) => {
                                log::error!("OutOfMemory");
                                control_flow.exit();
                            }
                            Err(wgpu::SurfaceError::Timeout) => {
                                log::warn!("Surface timeout");
                            }
                        }
                    }
                    _ => {}
                }
            }
        }
        _ => {}
    });
}

fn main() {
    pollster::block_on(run());
}
