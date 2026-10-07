module vui_evidence

pub struct WindowCapturePolicy {
pub:
	requested_background_mode bool = true
	target_was_foreground     bool
	no_activate               bool   = true
	capture_method            string = 'printwindow'
}

pub struct WindowCaptureDecision {
pub:
	requested_background_mode bool
	target_was_foreground     bool
	foreground_allowed        bool
	background_mode           bool
	no_activate               bool
	fallback_allowed          bool
	capture_method            string
	reason                    string
}

pub fn requested_background_mode(background_mode bool, nonintrusive bool) bool {
	return background_mode || nonintrusive
}

pub fn requested_background_mode_from_flags(has_background_flag bool, background_mode bool, nonintrusive bool) bool {
	if has_background_flag {
		return background_mode
	}
	return requested_background_mode(background_mode, nonintrusive)
}

pub fn decide_window_capture(policy WindowCapturePolicy) WindowCaptureDecision {
	foreground_allowed := !policy.requested_background_mode && policy.target_was_foreground
		&& !policy.no_activate
	background_mode := policy.requested_background_mode || !foreground_allowed
	fallback_allowed := !policy.requested_background_mode && policy.target_was_foreground
		&& !policy.no_activate
	return WindowCaptureDecision{
		requested_background_mode: policy.requested_background_mode
		target_was_foreground:     policy.target_was_foreground
		foreground_allowed:        foreground_allowed
		background_mode:           background_mode
		no_activate:               policy.no_activate || background_mode
		fallback_allowed:          fallback_allowed
		capture_method:            policy.capture_method
		reason:                    capture_reason(policy, foreground_allowed, background_mode)
	}
}

pub fn fallback_allowed_for_evidence(requested_background_mode bool, target_was_foreground bool) bool {
	return fallback_allowed_for_window_evidence(requested_background_mode, target_was_foreground,
		requested_background_mode)
}

pub fn fallback_allowed_for_window_evidence(requested_background_mode bool, target_was_foreground bool, no_activate bool) bool {
	return decide_window_capture(WindowCapturePolicy{
		requested_background_mode: requested_background_mode
		target_was_foreground:     target_was_foreground
		no_activate:               no_activate
	}).fallback_allowed
}

pub fn background_required_for_evidence(requested_background_mode bool, target_was_foreground bool) bool {
	return background_required_for_window_evidence(requested_background_mode,
		target_was_foreground, requested_background_mode)
}

pub fn background_required_for_window_evidence(requested_background_mode bool, target_was_foreground bool, no_activate bool) bool {
	return decide_window_capture(WindowCapturePolicy{
		requested_background_mode: requested_background_mode
		target_was_foreground:     target_was_foreground
		no_activate:               no_activate
	}).background_mode
}

fn capture_reason(policy WindowCapturePolicy, foreground_allowed bool, background_mode bool) string {
	if policy.requested_background_mode {
		return 'requested_background'
	}
	if foreground_allowed {
		return 'target_already_foreground'
	}
	if background_mode && !policy.target_was_foreground {
		return 'target_not_foreground'
	}
	return 'no_activate'
}
