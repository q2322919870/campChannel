import { reactive } from 'vue'

/**
 * 统一表单验证 composable
 * 提供常用的验证规则和错误管理
 */
export function useFormValidation<T extends Record<string, any>>(initialForm: T) {
  const form = reactive({ ...initialForm }) as T
  const errors = reactive<Record<string, string>>({})

  const validateEmail = (email: string): boolean => {
    const regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return regex.test(email)
  }

  const validateUsername = (username: string): boolean => {
    return username.length >= 3 && username.length <= 20
  }

  const validatePassword = (password: string): boolean => {
    return password.length >= 6 && password.length <= 64
  }

  const validateRequired = (value: any): boolean => {
    if (value === null || value === undefined) return false
    if (typeof value === 'string') return value.trim().length > 0
    if (Array.isArray(value)) return value.length > 0
    return true
  }

  const validatePhone = (phone: string): boolean => {
    const regex = /^1[3-9]\d{9}$/
    return regex.test(phone)
  }

  const validateMinLength = (value: string, min: number): boolean => {
    return value.length >= min
  }

  const validateMaxLength = (value: string, max: number): boolean => {
    return value.length <= max
  }

  const clearError = (field?: keyof T) => {
    if (field) {
      delete errors[field as string]
    } else {
      Object.keys(errors).forEach(k => delete errors[k])
    }
  }

  const resetForm = () => {
    Object.assign(form, initialForm)
    clearError()
  }

  return {
    form,
    errors,
    validateEmail,
    validateUsername,
    validatePassword,
    validateRequired,
    validatePhone,
    validateMinLength,
    validateMaxLength,
    clearError,
    resetForm,
  }
}
